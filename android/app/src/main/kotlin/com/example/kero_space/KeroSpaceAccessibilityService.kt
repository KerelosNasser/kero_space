package com.example.kero_space

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import com.example.kero_space.telemetry.BlacklistPreferencesStore

class KeroSpaceAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "KeroSpaceAccess"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                Log.d(TAG, "Window State Changed: $packageName")

                val json = JSONObject().apply {
                    put("type", "WINDOW_STATE")
                    put("packageName", packageName)
                    put("timestamp", System.currentTimeMillis())
                }.toString()

                // Push to both engines: main engine (UI/TelemetryBloc) and background engine (Isar).
                KeroSpaceForegroundService.accessibilityEventSink?.success(json)
                KeroSpaceForegroundService.bgAccessibilityEventSink?.success(json)

                runBlockerLogic(packageName)
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                val packageName = event.packageName?.toString() ?: ""
                val className = event.className?.toString() ?: ""
                val viewId = event.source?.viewIdResourceName ?: ""

                if (viewId.contains("password", ignoreCase = true) ||
                    viewId.contains("pin", ignoreCase = true) ||
                    viewId.contains("secret", ignoreCase = true)
                ) return

                val rawText = event.text?.joinToString(" ").ifEmpty { null }
                val sanitizedText = sanitizeText(rawText, viewId)

                val rect = Rect()
                event.source?.getBoundsInScreen(rect)
                val clickX = rect.centerX()
                val clickY = rect.centerY()

                val json = JSONObject().apply {
                    put("type", "CLICK")
                    put("packageName", packageName)
                    put("className", className)
                    put("viewId", viewId)
                    put("text", sanitizedText ?: JSONObject.NULL)
                    put("clickX", clickX)
                    put("clickY", clickY)
                    put("timestamp", System.currentTimeMillis())
                }.toString()

                KeroSpaceForegroundService.accessibilityEventSink?.success(json)
                KeroSpaceForegroundService.bgAccessibilityEventSink?.success(json)
            }
        }
    }

    private fun sanitizeText(text: String?, viewId: String): String? {
        if (text == null) return null

        if (viewId.contains("password", ignoreCase = true) ||
            viewId.contains("pin", ignoreCase = true) ||
            viewId.contains("secret", ignoreCase = true)) {
            return "[REDACTED]"
        }

        var sanitized = text.replace(Regex("\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}\\b"), "[CARD_REDACTED]")

        if (viewId.contains("email", ignoreCase = true) ||
            viewId.contains("login", ignoreCase = true) ||
            viewId.contains("username", ignoreCase = true) ||
            viewId.contains("signin", ignoreCase = true)) {
            sanitized = sanitized.replace(Regex("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"), "[EMAIL_REDACTED]")
        }

        return sanitized
    }

    /**
     * Checks if [packageName] is blocked and shows the overlay if not in an allowed window.
     *
     * Performance note: [BlacklistPreferencesStore.getBlockedPackages] caches its result
     * in memory and only re-reads EncryptedSharedPreferences when [saveRulesJson] is called.
     * Safe to call on every window-state event.
     */
    private fun runBlockerLogic(packageName: String) {
        try {
            val blocked = BlacklistPreferencesStore.getBlockedPackages(applicationContext)
            if (!blocked.contains(packageName)) return

            val rulesJson = BlacklistPreferencesStore.getRulesJson(applicationContext)
            var breakSeconds = 30
            var isAllowedWindow = false

            val arr = JSONArray(rulesJson)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.getString("packageName") == packageName) {
                    breakSeconds = obj.optInt("decisionBreakSeconds", 30)
                    isAllowedWindow = isCurrentTimeInAllowedWindows(obj)
                    break
                }
            }

            if (!isAllowedWindow) {
                if (OverlayManager.hasBreakBeenTakenRecently(packageName)) {
                    Log.d(TAG, "Blacklisted package $packageName opened but break already taken recently — allowing")
                    recordBlockerDecision(packageName, "granted")
                } else {
                    Log.d(TAG, "Blacklisted package opened: $packageName — showing overlay for ${breakSeconds}s")
                    OverlayManager.showOverlay(applicationContext, packageName, breakSeconds)
                    recordBlockerDecision(packageName, "blocked")
                }
            } else {
                Log.d(TAG, "Blacklisted package $packageName is in allowed window — access granted")
                recordBlockerDecision(packageName, "granted")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in blocker logic for $packageName", e)
        }
    }

    /**
     * Returns true if the current hour falls within any of the rule's allowed windows.
     * Windows are half-open intervals: [startHour, endHour).
     */
    private fun isCurrentTimeInAllowedWindows(ruleObj: JSONObject): Boolean {
        val windows = ruleObj.optJSONArray("allowedWindows") ?: return false
        if (windows.length() == 0) return false

        val currentHour = java.util.Calendar.getInstance().get(java.util.Calendar.HOUR_OF_DAY)

        for (i in 0 until windows.length()) {
            val window = windows.getJSONObject(i)
            val startHour = window.optInt("startHour", 0)
            val endHour = window.optInt("endHour", 24)
            if (currentHour in startHour until endHour) return true
        }
        return false
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
    }

    private fun recordBlockerDecision(packageName: String, outcome: String) {
        val json = JSONObject().apply {
            put("type", "BLOCKER_DECISION")
            put("packageName", packageName)
            put("outcome", outcome)
            put("timestamp", System.currentTimeMillis())
        }.toString()
        KeroSpaceForegroundService.accessibilityEventSink?.success(json)
        KeroSpaceForegroundService.bgAccessibilityEventSink?.success(json)
    }
}

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

    private var currentContext: String = SubAppDetector.CONTEXT_NORMAL
    private var currentPackage: String = ""
    private var contextStartTime: Long = 0
    private var isBlockedByQuota: Boolean = false

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
                    Log.d(TAG, "Window State Changed: $packageName")
                    val json = JSONObject().apply {
                        put("type", "WINDOW_STATE")
                        put("packageName", packageName)
                        put("timestamp", System.currentTimeMillis())
                    }.toString()
                    KeroSpaceForegroundService.accessibilityEventSink?.success(json)
                    KeroSpaceForegroundService.bgAccessibilityEventSink?.success(json)
                }
                runBlockerLogic(packageName, event)
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                val packageName = event.packageName?.toString() ?: ""
                val className = event.className?.toString() ?: ""
                val viewId = event.source?.viewIdResourceName ?: ""

                if (viewId.contains("password", ignoreCase = true) ||
                    viewId.contains("pin", ignoreCase = true) ||
                    viewId.contains("secret", ignoreCase = true)
                ) return

                val rawText = event.text?.joinToString(" ")?.ifEmpty { null }
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

    private fun runBlockerLogic(packageName: String, event: AccessibilityEvent) {
        try {
            val blocked = BlacklistPreferencesStore.getBlockedPackages(applicationContext)
            if (!blocked.contains(packageName)) {
                if (currentPackage != packageName) {
                    CounterOverlayManager.dismissCounter()
                    currentPackage = packageName
                    currentContext = SubAppDetector.CONTEXT_NORMAL
                }
                return
            }

            val rulesJson = BlacklistPreferencesStore.getRulesJson(applicationContext)
            var breakSeconds = 30
            var sessionLimitMinutes: Int? = null
            var subAppTarget: String? = null
            var isStrict = true
            var isAllowedWindow = false

            val arr = JSONArray(rulesJson)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.getString("packageName") == packageName) {
                    breakSeconds = obj.optInt("decisionBreakSeconds", 30)
                    if (obj.has("sessionLimitMinutes")) sessionLimitMinutes = obj.optInt("sessionLimitMinutes")
                    if (obj.has("subAppTarget")) subAppTarget = obj.getString("subAppTarget")
                    if (obj.has("strictMode")) isStrict = obj.optBoolean("strictMode", true)
                    isAllowedWindow = isCurrentTimeInAllowedWindows(obj)
                    break
                }
            }
            
            val detectedContext = SubAppDetector.detectContext(packageName, event)
            
            // Check if context changed
            if (currentPackage != packageName || currentContext != detectedContext) {
                currentPackage = packageName
                currentContext = detectedContext
                contextStartTime = System.currentTimeMillis()
                isBlockedByQuota = false
            }

            // Standard blacklist logic if no sub-app targeting or target matches
            if (subAppTarget == null || subAppTarget == detectedContext) {
                
                // Advanced session limits
                if (sessionLimitMinutes != null && sessionLimitMinutes > 0) {
                    val timeSpentMs = System.currentTimeMillis() - contextStartTime
                    val limitMs = sessionLimitMinutes * 60 * 1000L
                    
                    if (timeSpentMs > limitMs) {
                        if (!isBlockedByQuota) {
                            CounterOverlayManager.dismissCounter()
                            OverlayManager.showOverlay(applicationContext, packageName, 999999) // Strict block
                            recordBlockerDecision(packageName, "blocked_by_quota")
                            isBlockedByQuota = true
                        }
                    } else {
                        if (isBlockedByQuota) {
                            // User went back to normal context, dismiss block
                            OverlayManager.dismissOverlay(packageName)
                            isBlockedByQuota = false
                        }
                        // Show counter pill
                        CounterOverlayManager.showCounter(applicationContext, detectedContext, limitMs - timeSpentMs)
                    }
                    return
                }
                
                if (!isAllowedWindow) {
                    if (OverlayManager.hasBreakBeenTakenRecently(packageName)) {
                        recordBlockerDecision(packageName, "granted")
                    } else {
                        OverlayManager.showOverlay(applicationContext, packageName, breakSeconds)
                        recordBlockerDecision(packageName, "blocked")
                    }
                } else {
                    recordBlockerDecision(packageName, "granted")
                }
            } else {
                // If user is in the app, but NOT in the targeted sub-app, remove any restrictions/counters
                if (isBlockedByQuota) {
                    OverlayManager.dismissOverlay(packageName)
                    isBlockedByQuota = false
                }
                CounterOverlayManager.dismissCounter()
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

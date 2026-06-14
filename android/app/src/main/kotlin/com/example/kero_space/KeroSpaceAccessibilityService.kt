package com.example.kero_space

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import org.json.JSONObject
import com.example.kero_space.telemetry.BlacklistPreferencesStore

class KeroSpaceAccessibilityService : AccessibilityService() {
    private val TAG = "KeroSpaceAccess"

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

                KeroSpaceForegroundService.accessibilityEventSink?.success(json)

                // Direct Blocker Logic
                try {
                    val blockedPackages = BlacklistPreferencesStore.getBlockedPackages(applicationContext)
                    if (blockedPackages.contains(packageName)) {
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
                            Log.d(TAG, "Blacklisted package opened: $packageName. Showing overlay.")
                            OverlayManager.showOverlay(applicationContext, packageName, breakSeconds)
                        } else {
                            Log.d(TAG, "Blacklisted package $packageName is in allowed window. Access granted.")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error running blocker logic", e)
                }
            }
            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
                val packageName = event.packageName?.toString() ?: ""
                val className = event.className?.toString() ?: ""
                val viewId = event.source?.viewIdResourceName ?: ""
                
                // Privacy: Do not log clicks if it's a password field or numeric pattern
                if (viewId.contains("password", ignoreCase = true) || viewId.contains("pin", ignoreCase = true)) {
                    return
                }

                val json = JSONObject().apply {
                    put("type", "CLICK")
                    put("packageName", packageName)
                    put("className", className)
                    put("viewId", viewId)
                    put("timestamp", System.currentTimeMillis())
                }.toString()

                KeroSpaceForegroundService.accessibilityEventSink?.success(json)
            }
        }
    }

    private fun isCurrentTimeInAllowedWindows(ruleObj: JSONObject): Boolean {
        val windows = ruleObj.optJSONArray("allowedWindows") ?: return false
        if (windows.length() == 0) return false
        
        val calendar = java.util.Calendar.getInstance()
        val currentHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
        
        for (i in 0 until windows.length()) {
            val window = windows.getJSONObject(i)
            val startHour = window.optInt("startHour", 0)
            val endHour = window.optInt("endHour", 24)
            if (currentHour in startHour until endHour) {
                return true
            }
        }
        return false
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
    }
}

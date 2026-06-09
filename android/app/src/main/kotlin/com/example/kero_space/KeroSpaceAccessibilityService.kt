package com.example.kero_space

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import org.json.JSONObject

class KeroSpaceAccessibilityService : AccessibilityService() {
    private val TAG = "KeroSpaceAccess"

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                Log.d(TAG, "Window State Changed: \$packageName")
                
                val json = JSONObject().apply {
                    put("type", "WINDOW_STATE")
                    put("packageName", packageName)
                    put("timestamp", System.currentTimeMillis())
                }.toString()

                KeroSpaceForegroundService.accessibilityEventSink?.success(json)
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

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility Service Interrupted")
    }
}

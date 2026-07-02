package com.example.trobio

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.trobio.telemetry.BlacklistPreferencesStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

class KeroSpaceAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "KeroSpaceAccess"
        private val CARD_REGEX = Regex("\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}\\b")
        private val EMAIL_REGEX = Regex("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
    }

    private var currentContext: String = SubAppDetector.CONTEXT_NORMAL
    private var currentPackage: String = ""
    private var contextStartTime: Long = 0L
    private val cooldownExpiryByContext = ConcurrentHashMap<String, Long>()

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

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

            AccessibilityEvent.TYPE_VIEW_CLICKED,
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                val packageName = event.packageName?.toString() ?: ""
                val className = event.className?.toString() ?: ""
                val viewId = event.source?.viewIdResourceName ?: ""

                if (
                    viewId.contains("password", ignoreCase = true) ||
                    viewId.contains("pin", ignoreCase = true) ||
                    viewId.contains("secret", ignoreCase = true)
                ) {
                    return
                }

                val rawText = event.text?.joinToString(" ")?.ifEmpty { null }
                val rect = Rect()
                event.source?.getBoundsInScreen(rect)
                val clickX = rect.centerX()
                val clickY = rect.centerY()
                val timestamp = System.currentTimeMillis()

                serviceScope.launch {
                    val sanitizedText = sanitizeText(rawText, viewId)
                    withContext(Dispatchers.Main) {
                        val json = JSONObject().apply {
                            put("type", "CLICK")
                            put("packageName", packageName)
                            put("className", className)
                            put("viewId", viewId)
                            put("text", sanitizedText ?: JSONObject.NULL)
                            put("clickX", clickX)
                            put("clickY", clickY)
                            put("timestamp", timestamp)
                        }.toString()
                        KeroSpaceForegroundService.accessibilityEventSink?.success(json)
                        KeroSpaceForegroundService.bgAccessibilityEventSink?.success(json)
                    }
                }
            }
        }
    }

    private fun sanitizeText(text: String?, viewId: String): String? {
        if (text == null) return null

        var sanitized = text.replace(CARD_REGEX, "[CARD_REDACTED]")
        if (
            viewId.contains("email", ignoreCase = true) ||
            viewId.contains("login", ignoreCase = true) ||
            viewId.contains("username", ignoreCase = true) ||
            viewId.contains("signin", ignoreCase = true)
        ) {
            sanitized = sanitized.replace(EMAIL_REGEX, "[EMAIL_REDACTED]")
        }
        return sanitized
    }

    private fun runBlockerLogic(packageName: String, event: AccessibilityEvent) {
        try {
            val blockedPackages = BlacklistPreferencesStore.getBlockedPackages(applicationContext)
            if (!blockedPackages.contains(packageName)) {
                if (currentPackage != packageName) {
                    CounterOverlayManager.dismissCounter()
                    OverlayManager.dismissOverlay(shouldRecordBreak = false)
                    currentPackage = packageName
                    currentContext = SubAppDetector.CONTEXT_NORMAL
                }
                return
            }

            val rulesJson = BlacklistPreferencesStore.getRulesJson(applicationContext)
            var breakSeconds = 30
            var sessionLimitMinutes: Int? = null
            var cooldownMinutes: Int? = null
            var subAppTarget: String? = null
            var isAllowedWindow = false

            val arr = JSONArray(rulesJson)
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                if (obj.getString("packageName") == packageName) {
                    breakSeconds = obj.optInt("decisionBreakSeconds", 30)
                    if (obj.has("sessionLimitMinutes")) {
                        sessionLimitMinutes = obj.optInt("sessionLimitMinutes")
                    }
                    if (obj.has("cooldownMinutes")) {
                        cooldownMinutes = obj.optInt("cooldownMinutes")
                    }
                    if (obj.has("subAppTarget")) {
                        subAppTarget = obj.getString("subAppTarget")
                    }
                    isAllowedWindow = isCurrentTimeInAllowedWindows(obj)
                    break
                }
            }

            val detectedContext = SubAppDetector.detectContext(packageName, event)
            val contextKey = "$packageName::$detectedContext"
            val now = System.currentTimeMillis()

            if (currentPackage != packageName || currentContext != detectedContext) {
                currentPackage = packageName
                currentContext = detectedContext
                contextStartTime = now
                CounterOverlayManager.dismissCounter()
            }

            if (subAppTarget != null && subAppTarget != detectedContext) {
                CounterOverlayManager.dismissCounter()
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
                return
            }

            val cooldownUntil = cooldownExpiryByContext[contextKey] ?: 0L
            if (cooldownUntil > now) {
                CounterOverlayManager.dismissCounter()
                val remainingSeconds = ((cooldownUntil - now) / 1000L).coerceAtLeast(1L).toInt()
                OverlayManager.showOverlay(
                    context = applicationContext,
                    packageName = packageName,
                    durationSeconds = remainingSeconds,
                    title = "Cooldown Active",
                    subtitle = "Blocked until cooldown ends",
                    shouldRecordBreakOnDismiss = false,
                )
                return
            } else if (cooldownUntil != 0L) {
                cooldownExpiryByContext.remove(contextKey)
                contextStartTime = now
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
            }

            if (sessionLimitMinutes != null && sessionLimitMinutes > 0) {
                val timeSpentMs = now - contextStartTime
                val limitMs = sessionLimitMinutes * 60 * 1000L
                if (timeSpentMs >= limitMs) {
                    CounterOverlayManager.dismissCounter()
                    val cooldownMs = ((cooldownMinutes ?: 60) * 60 * 1000L).toLong()
                    val cooldownEndsAt = now + cooldownMs
                    cooldownExpiryByContext[contextKey] = cooldownEndsAt
                    OverlayManager.showOverlay(
                        context = applicationContext,
                        packageName = packageName,
                        durationSeconds = (cooldownMs / 1000L).toInt(),
                        title = "Cooldown Active",
                        subtitle = "Take a break before reopening",
                        shouldRecordBreakOnDismiss = false,
                    )
                    recordBlockerDecision(packageName, "blocked_by_cooldown")
                    return
                }

                CounterOverlayManager.showCounter(
                    applicationContext,
                    detectedContext,
                    limitMs - timeSpentMs,
                )
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
                return
            }

            CounterOverlayManager.dismissCounter()
            if (isAllowedWindow) {
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
                recordBlockerDecision(packageName, "granted")
                return
            }

            val recentBreakCooldownMinutes = cooldownMinutes ?: 15
            if (OverlayManager.hasBreakBeenTakenRecently(packageName, recentBreakCooldownMinutes)) {
                recordBlockerDecision(packageName, "granted")
                return
            }

            OverlayManager.showOverlay(
                context = applicationContext,
                packageName = packageName,
                durationSeconds = breakSeconds,
                title = "Decision Break",
                subtitle = "Pause before jumping back in",
                shouldRecordBreakOnDismiss = true,
            )
            recordBlockerDecision(packageName, "blocked")
        } catch (e: Exception) {
            Log.e(TAG, "Error in blocker logic for $packageName", e)
        }
    }

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

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
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

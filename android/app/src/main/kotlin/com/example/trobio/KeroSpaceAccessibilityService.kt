package com.example.trobio

import android.accessibilityservice.AccessibilityService
import android.graphics.Rect
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import com.example.trobio.telemetry.BlacklistPreferencesStore
import com.example.trobio.telemetry.ParsedRule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.util.Calendar
import java.util.concurrent.ConcurrentHashMap

class KeroSpaceAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "KeroSpaceAccess"
        private val CARD_REGEX = Regex("\\b\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}[-\\s]?\\d{4}\\b")
        private val EMAIL_REGEX = Regex("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
        private const val CONTENT_CHANGE_DEBOUNCE_MS = 300L
    }

    private var currentContext: String = SubAppDetector.CONTEXT_NORMAL
    private var currentPackage: String = ""
    private var contextStartTime: Long = 0L
    private val cooldownExpiryByContext = ConcurrentHashMap<String, Long>()
    private val lastContentCheckTimeByPackage = ConcurrentHashMap<String, Long>()

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

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

                KeroSpaceForegroundService.accessibilityEventSink.safeSuccess(json)
                KeroSpaceForegroundService.bgAccessibilityEventSink.safeSuccess(json)

                runBlockerLogic(packageName, event)
            }

            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                // Fast path: Only process content changes for packages with sub-app contexts (Instagram, YouTube, TikTok)
                if (!SubAppDetector.isCandidatePackage(packageName)) return

                // Debounce content checks to prevent frame drops during scrolling
                val nowUptime = SystemClock.uptimeMillis()
                val lastCheck = lastContentCheckTimeByPackage[packageName] ?: 0L
                if (nowUptime - lastCheck < CONTENT_CHANGE_DEBOUNCE_MS) {
                    return
                }
                lastContentCheckTimeByPackage[packageName] = nowUptime

                runBlockerLogic(packageName, event)
            }

            AccessibilityEvent.TYPE_VIEW_CLICKED -> {
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

                val rawText = event.text.joinToString(" ").ifEmpty { null }
                val rect = Rect()
                event.source?.getBoundsInScreen(rect)
                val clickX = rect.centerX()
                val clickY = rect.centerY()
                val timestamp = System.currentTimeMillis()

                serviceScope.launch {
                    val sanitizedText = sanitizeText(rawText, viewId)
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

                    KeroSpaceForegroundService.accessibilityEventSink.safeSuccess(json)
                    KeroSpaceForegroundService.bgAccessibilityEventSink.safeSuccess(json)
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
            val rule = BlacklistPreferencesStore.getRule(applicationContext, packageName)
            if (rule == null) {
                if (currentPackage != packageName) {
                    CounterOverlayManager.dismissCounter()
                    OverlayManager.dismissOverlay(shouldRecordBreak = false)
                    currentPackage = packageName
                    currentContext = SubAppDetector.CONTEXT_NORMAL
                }
                return
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

            // If a specific sub-app target was set (e.g. reels) and current context doesn't match, allow through
            if (rule.subAppTarget != null && rule.subAppTarget != detectedContext) {
                CounterOverlayManager.dismissCounter()
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
                return
            }

            // Cooldown check
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

            // Session limit check
            val sessionLimitMinutes = rule.sessionLimitMinutes
            if (sessionLimitMinutes != null && sessionLimitMinutes > 0) {
                val timeSpentMs = now - contextStartTime
                val limitMs = sessionLimitMinutes * 60 * 1000L
                if (timeSpentMs >= limitMs) {
                    CounterOverlayManager.dismissCounter()
                    val cooldownMs = (rule.cooldownMinutes ?: 60) * 60 * 1000L
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

            // Allowed schedule window check
            val currentHour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
            if (rule.isAllowedAt(currentHour)) {
                OverlayManager.dismissOverlay(shouldRecordBreak = false)
                recordBlockerDecision(packageName, "granted")
                return
            }

            // Recent decision break cooldown check
            val recentBreakCooldownMinutes = rule.cooldownMinutes ?: 15
            if (OverlayManager.hasBreakBeenTakenRecently(packageName, recentBreakCooldownMinutes)) {
                recordBlockerDecision(packageName, "granted")
                return
            }

            // Decision break trigger
            OverlayManager.showOverlay(
                context = applicationContext,
                packageName = packageName,
                durationSeconds = rule.decisionBreakSeconds,
                title = "Decision Break",
                subtitle = "Pause before jumping back in",
                shouldRecordBreakOnDismiss = true,
            )
            recordBlockerDecision(packageName, "blocked")
        } catch (e: Exception) {
            Log.e(TAG, "Error in blocker logic for $packageName", e)
        }
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
        KeroSpaceForegroundService.accessibilityEventSink.safeSuccess(json)
        KeroSpaceForegroundService.bgAccessibilityEventSink.safeSuccess(json)
    }
}

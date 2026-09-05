package com.example.trobio

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.view.accessibility.AccessibilityManager
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Centralised controller for the four Omniscient Layer agents.
 */
object AgentManager {

    private const val TAG = "AgentManager"
    private const val USAGE_WORK_NAME = "UsageStatsWorker"

    fun handleAgentToggle(context: Context, agentId: String, enabled: Boolean) {
        when (agentId) {
            "wake_word" -> {
                val intent = Intent(context, WakeWordService::class.java)
                if (enabled) {
                    val hasMic = androidx.core.content.ContextCompat.checkSelfPermission(
                        context,
                        android.Manifest.permission.RECORD_AUDIO,
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    if (hasMic) {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                context.startForegroundService(intent)
                            } else {
                                context.startService(intent)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to start WakeWordService: ${e.message}", e)
                        }
                    } else {
                        Log.w(TAG, "Cannot start WakeWordService: RECORD_AUDIO permission not granted")
                    }
                } else {
                    try {
                        context.stopService(intent)
                    } catch (e: Exception) {
                        Log.w(TAG, "Error stopping WakeWordService: ${e.message}")
                    }
                }
            }
            "usage_guard" -> {
                if (enabled) {
                    val constraints = Constraints.Builder()
                        .setRequiresBatteryNotLow(true)
                        .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                        .build()
                    val workRequest = PeriodicWorkRequestBuilder<UsageStatsWorker>(15, TimeUnit.MINUTES)
                        .setConstraints(constraints)
                        .build()
                    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                        USAGE_WORK_NAME,
                        ExistingPeriodicWorkPolicy.KEEP,
                        workRequest,
                    )
                    _usageGuardScheduled = true
                } else {
                    WorkManager.getInstance(context).cancelUniqueWork(USAGE_WORK_NAME)
                    _usageGuardScheduled = false
                }
            }
            "screen_event" -> {
                Log.d(TAG, "screen_event toggle=$enabled (managed by foreground service lifecycle)")
            }
            "accessibility" -> {
                try {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to open accessibility settings", e)
                }
            }
            else -> Log.w(TAG, "Unknown agentId: $agentId")
        }
    }

    fun buildAgentStatusMap(context: Context): Map<String, Boolean> = mapOf(
        "accessibility" to isAccessibilityEnabled(context),
        "usage_guard" to isUsageGuardScheduled(context),
        "screen_event" to KeroSpaceForegroundService.isRunning,
        "wake_word" to WakeWordService.isRunning,
    )

    fun isAccessibilityEnabled(context: Context): Boolean {
        // Method 1: Check AccessibilityManager enabled service list
        val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
        val enabledServices = am?.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        if (enabledServices != null) {
            for (service in enabledServices) {
                val serviceInfo = service.resolveInfo?.serviceInfo
                if (serviceInfo != null &&
                    serviceInfo.packageName == context.packageName &&
                    serviceInfo.name == KeroSpaceAccessibilityService::class.java.name) {
                    return true
                }
            }
        }

        // Method 2: Fallback to Settings.Secure check for both full and short formats
        val setting = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false

        val fullSvc = "${context.packageName}/${KeroSpaceAccessibilityService::class.java.name}"
        val shortSvc = "${context.packageName}/.${KeroSpaceAccessibilityService::class.java.simpleName}"
        return setting.contains(fullSvc) || setting.contains(shortSvc)
    }

    private var _usageGuardScheduled = false

    fun refreshUsageGuardCachedState(context: Context) {
        val future = WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(USAGE_WORK_NAME)
        future.addListener(
            {
                _usageGuardScheduled = try {
                    future.get().any {
                        it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.RUNNING
                    }
                } catch (_: Exception) {
                    false
                }
            },
            java.util.concurrent.Executors.newSingleThreadExecutor(),
        )
    }

    private fun isUsageGuardScheduled(context: Context): Boolean = _usageGuardScheduled

    // --- Productivity Tab Enhancements ---
    var isTaskGatedModeEnabled = false
    var hasPendingHighPriorityTask = false
    var deepWorkEndTimeMs: Long = 0

    fun setTaskGatedMode(context: Context, enabled: Boolean) {
        isTaskGatedModeEnabled = enabled
        Log.d(TAG, "Task Gated Mode: $enabled")
    }

    fun setPendingHighPriorityTask(context: Context, hasTask: Boolean) {
        hasPendingHighPriorityTask = hasTask
        Log.d(TAG, "Pending High Priority Task: $hasTask")
    }

    fun startDeepWork(context: Context, durationMinutes: Int) {
        deepWorkEndTimeMs = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)
        Log.d(TAG, "Deep Work started for $durationMinutes mins")
    }

    fun isDeepWorkActive(): Boolean {
        return System.currentTimeMillis() < deepWorkEndTimeMs
    }
}

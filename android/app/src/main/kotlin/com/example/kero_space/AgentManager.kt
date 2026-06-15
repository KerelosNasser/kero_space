package com.example.kero_space

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Centralised controller for the four Omniscient Layer agents.
 *
 * Previously, [handleAgentToggle], [buildAgentStatusMap], and the helper
 * [isServiceRunning] / [isAccessibilityEnabled] / [isUsageGuardScheduled]
 * functions were copy-pasted verbatim into both [MainActivity] and
 * [KeroSpaceForegroundService]. This object is the single source-of-truth.
 */
object AgentManager {

    private const val TAG = "AgentManager"
    private const val USAGE_WORK_NAME = "UsageStatsWorker"

    fun handleAgentToggle(context: Context, agentId: String, enabled: Boolean) {
        when (agentId) {
            "wake_word" -> {
                val intent = Intent(context, WakeWordService::class.java)
                if (enabled) {
                    val hasMic = androidx.core.content.ContextCompat.checkSelfPermission(context, android.Manifest.permission.RECORD_AUDIO) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    if (hasMic) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(intent)
                        } else {
                            context.startService(intent)
                        }
                    } else {
                        Log.w(TAG, "Cannot start WakeWordService: RECORD_AUDIO permission not granted")
                    }
                } else {
                    context.stopService(intent)
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
                } else {
                    WorkManager.getInstance(context).cancelUniqueWork(USAGE_WORK_NAME)
                }
            }
            "screen_event" -> {
                // Screen receiver is lifecycle-managed by KeroSpaceForegroundService.
                // Toggling is currently a no-op from Dart side — the receiver lives
                // as long as the foreground service does.
                Log.d(TAG, "screen_event toggle=$enabled (managed by foreground service lifecycle)")
            }
            "accessibility" -> {
                // Cannot programmatically enable accessibility — open settings for user.
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
        val svc = "${context.packageName}/${KeroSpaceAccessibilityService::class.java.name}"
        return (Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: "").contains(svc)
    }

    private fun isUsageGuardScheduled(context: Context): Boolean {
        return try {
            WorkManager.getInstance(context)
                .getWorkInfosForUniqueWork(USAGE_WORK_NAME)
                .get(2, java.util.concurrent.TimeUnit.SECONDS)
                .any { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.RUNNING }
        } catch (e: java.util.concurrent.TimeoutException) {
            Log.w(TAG, "isUsageGuardScheduled timed out — returning false")
            false
        } catch (e: Exception) {
            Log.e(TAG, "isUsageGuardScheduled error", e)
            false
        }
    }

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

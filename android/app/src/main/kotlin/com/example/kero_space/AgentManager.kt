package com.example.kero_space

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.work.ExistingPeriodicWorkPolicy
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
                    context.startService(intent)
                } else {
                    context.stopService(intent)
                }
            }
            "usage_guard" -> {
                if (enabled) {
                    WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                        USAGE_WORK_NAME,
                        ExistingPeriodicWorkPolicy.KEEP,
                        PeriodicWorkRequestBuilder<UsageStatsWorker>(15, TimeUnit.MINUTES).build(),
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
        "screen_event" to isServiceRunning(context, KeroSpaceForegroundService::class.java),
        "wake_word" to isServiceRunning(context, WakeWordService::class.java),
    )

    @Suppress("DEPRECATION")
    private fun isServiceRunning(context: Context, cls: Class<*>): Boolean =
        (context.getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager)
            .getRunningServices(Int.MAX_VALUE)
            .any { it.service.className == cls.name }

    fun isAccessibilityEnabled(context: Context): Boolean {
        val svc = "${context.packageName}/${KeroSpaceAccessibilityService::class.java.name}"
        return (Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: "").contains(svc)
    }

    private fun isUsageGuardScheduled(context: Context): Boolean =
        WorkManager.getInstance(context)
            .getWorkInfosForUniqueWork(USAGE_WORK_NAME)
            .get()
            .any { it.state == WorkInfo.State.ENQUEUED || it.state == WorkInfo.State.RUNNING }
}

package com.example.kero_space

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.ListenableWorker.Result
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * Periodic WorkManager task that queries Android UsageStatsManager every 15 minutes
 * and broadcasts the result to [KeroSpaceForegroundService] for forwarding to Dart.
 */
class UsageStatsWorker(appContext: Context, workerParams: WorkerParameters) :
    Worker(appContext, workerParams) {

    companion object {
        private const val TAG = "KeroSpaceUsageStats"
    }

    override fun doWork(): Result {
        Log.d(TAG, "doWork: Querying UsageStatsManager")

        val usageStatsManager = applicationContext
            .getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: run {
                Log.e(TAG, "USAGE_STATS_SERVICE not available")
                return Result.failure()
            }

        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.MINUTE, -15)
        val startTime = calendar.timeInMillis

        // INTERVAL_BEST: lets Android pick the smallest available interval that covers
        // our 15-minute window. INTERVAL_DAILY would return daily aggregates regardless
        // of the requested time window, making the window parameters meaningless.
        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST,
            startTime,
            endTime,
        )

        if (usageStatsList.isNullOrEmpty()) {
            Log.w(TAG, "No usage stats returned. Check PACKAGE_USAGE_STATS permission.")
            // Return success to avoid WorkManager retrying — permission must be granted by user.
            return Result.success()
        }

        val jsonArray = JSONArray()
        for (usageStats in usageStatsList) {
            if (usageStats.totalTimeInForeground > 0) {
                jsonArray.put(JSONObject().apply {
                    put("packageName", usageStats.packageName)
                    put("foregroundTimeMs", usageStats.totalTimeInForeground)
                    put("lastTimeUsed", usageStats.lastTimeUsed)
                })
            }
        }

        Log.d(TAG, "Queried ${jsonArray.length()} apps with foreground time. Broadcasting.")

        val intent = Intent("com.example.kero_space.USAGE_STATS_READY").apply {
            putExtra("payload", jsonArray.toString())
            setPackage(applicationContext.packageName)
        }
        applicationContext.sendBroadcast(intent)

        return Result.success()
    }
}

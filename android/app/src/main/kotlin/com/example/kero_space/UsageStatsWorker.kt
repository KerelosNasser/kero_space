package com.example.kero_space

import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

class UsageStatsWorker(appContext: Context, workerParams: WorkerParameters) :
    Worker(appContext, workerParams) {

    private val TAG = "KeroSpaceUsageStats"

    override fun doWork(): Result {
        Log.d(TAG, "doWork: Querying UsageStatsManager")
        
        val usageStatsManager = applicationContext.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.MINUTE, -15) // Query last 15 minutes
        val startTime = calendar.timeInMillis

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        if (usageStatsList.isNullOrEmpty()) {
            Log.d(TAG, "No usage stats found. Does the app have permission?")
            return Result.success()
        }

        val jsonArray = JSONArray()
        
        for (usageStats in usageStatsList) {
            if (usageStats.totalTimeInForeground > 0) {
                val obj = JSONObject().apply {
                    put("packageName", usageStats.packageName)
                    put("foregroundTimeMs", usageStats.totalTimeInForeground)
                    put("lastTimeUsed", usageStats.lastTimeUsed)
                }
                jsonArray.put(obj)
            }
        }

        // Ideally, we emit this to Dart if Dart is listening.
        // However, this is a background worker. 
        // We can use a broadcast intent to the ForegroundService, which will forward it to Dart.
        
        val intent = android.content.Intent("com.example.kero_space.USAGE_STATS_READY")
        intent.putExtra("payload", jsonArray.toString())
        applicationContext.sendBroadcast(intent)

        return Result.success()
    }
}

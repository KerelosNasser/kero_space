package com.example.kero_space

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "kero_space/main_methods"
    private val TAG = "MainActivity"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startForegroundService") {
                val serviceIntent = Intent(this, KeroSpaceForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                result.success("Started")
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/calendar").setMethodCallHandler(
            CalendarChannelHandler(this)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/methods").setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    val packageName = call.argument<String>("packageName") ?: ""
                    val duration = call.argument<Int>("durationSeconds") ?: 0
                    Log.d(TAG, "Dart requested showOverlay for $packageName")
                    OverlayManager.showOverlay(applicationContext, packageName, duration)
                    result.success(null)
                }
                "dismissOverlay" -> {
                    OverlayManager.dismissOverlay()
                    result.success(null)
                }
                "setBlacklistRules" -> {
                    val rulesJson = call.argument<String>("rulesJson") ?: "[]"
                    com.example.kero_space.telemetry.BlacklistPreferencesStore.saveRulesJson(applicationContext, rulesJson)
                    result.success(null)
                }
                "toggleAgent" -> {
                    val agentId = call.argument<String>("agentId") ?: ""
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    handleAgentToggle(agentId, enabled)
                    result.success(null)
                }
                "getAgentStatuses" -> {
                    result.success(buildAgentStatusMap())
                }
                else -> result.notImplemented()
            }
        }

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/wake_word").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.wakeWordEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.wakeWordEventSink = null
                }
            }
        )

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/screen_events").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.screenEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.screenEventSink = null
                }
            }
        )

        io.flutter.plugin.common.EventChannel(flutterEngine.dartExecutor.binaryMessenger, "kero_space/accessibility").setStreamHandler(
            object : io.flutter.plugin.common.EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: io.flutter.plugin.common.EventChannel.EventSink?) {
                    KeroSpaceForegroundService.accessibilityEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    KeroSpaceForegroundService.accessibilityEventSink = null
                }
            }
        )
    }

    private fun handleAgentToggle(agentId: String, enabled: Boolean) {
        when (agentId) {
            "wake_word" -> {
                val intent = Intent(this, WakeWordService::class.java)
                if (enabled) {
                    startService(intent)
                } else stopService(intent)
            }
            "usage_guard" -> {
                if (enabled) {
                    androidx.work.WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                        "UsageStatsWorker", androidx.work.ExistingPeriodicWorkPolicy.KEEP,
                        androidx.work.PeriodicWorkRequestBuilder<UsageStatsWorker>(15, java.util.concurrent.TimeUnit.MINUTES).build()
                    )
                } else {
                    androidx.work.WorkManager.getInstance(this).cancelUniqueWork("UsageStatsWorker")
                }
            }
            "screen_event" -> {
                sendBroadcast(Intent("kero_space.TOGGLE_SCREEN_RECEIVER").putExtra("enabled", enabled))
            }
            "accessibility" -> {
                val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        }
    }

    private fun buildAgentStatusMap(): Map<String, Boolean> = mapOf(
        "accessibility" to isAccessibilityEnabled(),
        "usage_guard" to isUsageGuardScheduled(),
        "screen_event" to isServiceRunning(KeroSpaceForegroundService::class.java),
        "wake_word" to isServiceRunning(WakeWordService::class.java),
    )

    private fun isServiceRunning(cls: Class<*>): Boolean {
        @Suppress("DEPRECATION")
        return (getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager)
            .getRunningServices(Int.MAX_VALUE).any { it.service.className == cls.name }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val svc = "$packageName/${KeroSpaceAccessibilityService::class.java.name}"
        return (android.provider.Settings.Secure.getString(contentResolver, android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES) ?: "").contains(svc)
    }

    private fun isUsageGuardScheduled(): Boolean =
        androidx.work.WorkManager.getInstance(this).getWorkInfosForUniqueWork("UsageStatsWorker").get()
            .any { it.state == androidx.work.WorkInfo.State.ENQUEUED || it.state == androidx.work.WorkInfo.State.RUNNING }
}

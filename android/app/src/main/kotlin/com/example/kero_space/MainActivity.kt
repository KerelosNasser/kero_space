package com.example.kero_space

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val MAIN_METHODS_CHANNEL = "kero_space/main_methods"
        private const val METHODS_CHANNEL = "kero_space/methods"
        private const val CALENDAR_CHANNEL = "kero_space/calendar"
    }

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
        setupMainMethodsChannel(flutterEngine)
        setupMethodsChannel(flutterEngine)
        setupEventChannels(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL)
            .setMethodCallHandler(CalendarChannelHandler(this))
    }

    // ─── kero_space/main_methods ────────────────────────────────────────────

    private fun setupMainMethodsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_METHODS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startForegroundService" -> {
                        val serviceIntent = Intent(this, KeroSpaceForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success("Started")
                    }
                    "checkAccessibility" -> {
                        result.success(AgentManager.isAccessibilityEnabled(this))
                    }
                    "checkUsageStats" -> {
                        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            appOps.unsafeCheckOpNoThrow(
                                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                                android.os.Process.myUid(),
                                packageName,
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            appOps.checkOpNoThrow(
                                android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
                                android.os.Process.myUid(),
                                packageName,
                            )
                        }
                        result.success(mode == android.app.AppOpsManager.MODE_ALLOWED)
                    }
                    "checkNotificationListener" -> {
                        val enabled = androidx.core.app.NotificationManagerCompat
                            .getEnabledListenerPackages(applicationContext)
                        result.success(enabled.contains(packageName))
                    }
                    "openAccessibilitySettings" -> {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to open accessibility settings", e)
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "openUsageStatsSettings" -> {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to open usage access settings", e)
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "openNotificationListenerSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                                Intent(android.provider.Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            } else {
                                Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                            }.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                            startActivity(intent)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to open notification settings", e)
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─── kero_space/methods ─────────────────────────────────────────────────

    private fun setupMethodsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHODS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showOverlay" -> {
                        val pkg = call.argument<String>("packageName") ?: ""
                        val dur = call.argument<Int>("durationSeconds") ?: 0
                        Log.d(TAG, "Dart requested showOverlay for $pkg")
                        OverlayManager.showOverlay(applicationContext, pkg, dur)
                        result.success(null)
                    }
                    "dismissOverlay" -> {
                        OverlayManager.dismissOverlay()
                        result.success(null)
                    }
                    "setBlacklistRules" -> {
                        val rulesJson = call.argument<String>("rulesJson") ?: "[]"
                        try {
                            org.json.JSONArray(rulesJson)
                            com.example.kero_space.telemetry.BlacklistPreferencesStore
                                .saveRulesJson(applicationContext, rulesJson)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("INVALID_JSON", "Rules must be a valid JSON array", null)
                        }
                    }
                    "toggleAgent" -> {
                        val agentId = call.argument<String>("agentId") ?: ""
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        AgentManager.handleAgentToggle(this, agentId, enabled)
                        result.success(null)
                    }
                    "getAgentStatuses" -> {
                        result.success(AgentManager.buildAgentStatusMap(this))
                    }
                    "setTaskGatedMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        AgentManager.setTaskGatedMode(applicationContext, enabled)
                        result.success(null)
                    }
                    "setPendingHighPriorityTask" -> {
                        val hasTask = call.argument<Boolean>("hasTask") ?: false
                        AgentManager.setPendingHighPriorityTask(applicationContext, hasTask)
                        result.success(null)
                    }
                    "startDeepWork" -> {
                        val durationMinutes = call.argument<Int>("durationMinutes") ?: 25
                        AgentManager.startDeepWork(applicationContext, durationMinutes)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─── EventChannels (main engine ↔ Dart UI) ───────────────────────────────

    private fun setupEventChannels(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        listOf(
            "kero_space/wake_word" to { sink: EventChannel.EventSink? ->
                KeroSpaceForegroundService.wakeWordEventSink = sink
            },
            "kero_space/screen_events" to { sink: EventChannel.EventSink? ->
                KeroSpaceForegroundService.screenEventSink = sink
            },
            "kero_space/accessibility" to { sink: EventChannel.EventSink? ->
                KeroSpaceForegroundService.accessibilityEventSink = sink
            },
            "kero_space/usage_stats" to { sink: EventChannel.EventSink? ->
                KeroSpaceForegroundService.usageStatsEventSink = sink
            },
        ).forEach { (channelName, assign) ->
            EventChannel(messenger, channelName).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = assign(events)
                    override fun onCancel(arguments: Any?) = assign(null)
                },
            )
        }
    }
}

package com.example.trobio

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat
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

    override fun onDestroy() {
        KeroSpaceForegroundService.wakeWordEventSink = null
        KeroSpaceForegroundService.screenEventSink = null
        KeroSpaceForegroundService.accessibilityEventSink = null
        KeroSpaceForegroundService.usageStatsEventSink = null
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        setupMainMethodsChannel(flutterEngine)
        setupMethodsChannel(flutterEngine)
        setupEventChannels(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALENDAR_CHANNEL)
            .setMethodCallHandler(CalendarChannelHandler(this))
    }

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
                        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            appOps.unsafeCheckOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                android.os.Process.myUid(),
                                packageName,
                            )
                        } else {
                            @Suppress("DEPRECATION")
                            appOps.checkOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                android.os.Process.myUid(),
                                packageName,
                            )
                        }
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    }

                    "checkOverlayPermission" -> {
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                Settings.canDrawOverlays(this)
                            } else {
                                true
                            },
                        )
                    }

                    "checkNotificationListener" -> {
                        val enabled = NotificationManagerCompat
                            .getEnabledListenerPackages(applicationContext)
                        result.success(enabled.contains(packageName))
                    }

                    "openAccessibilitySettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
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
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            })
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to open usage access settings", e)
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }

                    "openOverlaySettings" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                        Uri.parse("package:$packageName"),
                                    ).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    },
                                )
                            } else {
                                startActivity(Intent(Settings.ACTION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                })
                            }
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to open overlay settings", e)
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }

                    "openNotificationListenerSettings" -> {
                        try {
                            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            } else {
                                Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                            }.apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
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
                            com.example.trobio.telemetry.BlacklistPreferencesStore
                                .saveRulesJson(applicationContext, rulesJson)
                            result.success(null)
                        } catch (_: Exception) {
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

    private fun setupEventChannels(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val mainChannels = mapOf(
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
        )

        mainChannels.forEach { (channelName, assign) ->
            EventChannel(messenger, channelName).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        Log.d(TAG, "stream onListen — $channelName")
                        assign(events)
                    }

                    override fun onCancel(arguments: Any?) {
                        Log.d(TAG, "stream onCancel — $channelName")
                        try {
                            assign(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "stream onCancel err — $channelName", e)
                        }
                    }
                },
            )
        }
    }
}

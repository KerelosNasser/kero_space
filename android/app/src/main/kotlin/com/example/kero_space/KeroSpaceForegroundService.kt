package com.example.kero_space

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class KeroSpaceForegroundService : Service() {

    companion object {
        private const val TAG = "KeroSpaceFS"
        private const val CHANNEL_ID = "kero_space_foreground_channel"
        private const val FGS_NOTIFICATION_ID = 1

        // EventSinks shared with the main-engine EventChannels registered in MainActivity.
        // Written by the background headless engine (setupChannels) and the main engine
        // (MainActivity.setupEventChannels); at runtime only one engine is active per sink.
        @Volatile var screenEventSink: EventChannel.EventSink? = null
        @Volatile var accessibilityEventSink: EventChannel.EventSink? = null
        @Volatile var wakeWordEventSink: EventChannel.EventSink? = null
        @Volatile var usageStatsEventSink: EventChannel.EventSink? = null
    }

    private var flutterEngine: FlutterEngine? = null
    private var screenReceiver: KeroSpaceScreenReceiver? = null

    private val usageStatsReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val payload = intent?.getStringExtra("payload") ?: return
            Log.d(TAG, "USAGE_STATS_READY received — forwarding to Dart")
            usageStatsEventSink?.success(payload)
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate")
        createNotificationChannel()
        startForegroundWithNotification()
        registerReceivers()
        startFlutterEngine()
        startService(Intent(this, WakeWordService::class.java))
    }

    /**
     * START_STICKY restarts the service if killed.
     * We do NOT call startForegroundWithNotification() here — it was already
     * called in onCreate() and calling it again on every onStartCommand causes
     * a redundant foreground promotion each time the service is restarted.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        unregisterReceiverSafe(screenReceiver)
        unregisterReceiverSafe(usageStatsReceiver)
        flutterEngine?.destroy()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /** Android 15+ dataSync FGS timeout — log and self-stop gracefully. */
    override fun onTimeout(startId: Int) {
        Log.w(TAG, "FGS onTimeout (Android 15+ dataSync limit). Stopping self.")
        stopSelf(startId)
    }

    // ─── Setup ───────────────────────────────────────────────────────────────

    private fun registerReceivers() {
        screenReceiver = KeroSpaceScreenReceiver()
        val screenFilter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        val usageFilter = IntentFilter("com.example.kero_space.USAGE_STATS_READY")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenReceiver, screenFilter, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(usageStatsReceiver, usageFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenReceiver, screenFilter)
            registerReceiver(usageStatsReceiver, usageFilter)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kero Space Omniscient Layer",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Keeps background agents running" }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Kero Space Active")
            .setContentText("Omniscient layer is monitoring...")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var serviceTypes = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val hasMic = androidx.core.content.ContextCompat.checkSelfPermission(
                    this, android.Manifest.permission.RECORD_AUDIO,
                ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                if (hasMic) {
                    serviceTypes = serviceTypes or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                } else {
                    Log.w(TAG, "RECORD_AUDIO not granted — excluding microphone FGS type")
                }
            }
            startForeground(FGS_NOTIFICATION_ID, notification, serviceTypes)
        } else {
            startForeground(FGS_NOTIFICATION_ID, notification)
        }
    }

    // ─── Headless Flutter Engine ─────────────────────────────────────────────

    private fun startFlutterEngine() {
        try {
            val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
            flutterLoader.startInitialization(applicationContext)
            flutterLoader.ensureInitializationComplete(applicationContext, null)

            flutterEngine = FlutterEngine(applicationContext)
            setupChannels()

            val entrypoint = DartExecutor.DartEntrypoint(
                flutterLoader.findAppBundlePath(),
                "backgroundMain",
            )
            flutterEngine?.dartExecutor?.executeDartEntrypoint(entrypoint)
            Log.d(TAG, "Headless FlutterEngine started — backgroundMain executing")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialise Headless FlutterEngine", e)
        }
    }

    /**
     * Registers EventChannels and a MethodChannel on the headless engine's messenger.
     * These run in the background Dart isolate (backgroundMain), independently of
     * the main engine's channels registered in [MainActivity].
     */
    private fun setupChannels() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return

        listOf(
            "kero_space/screen_events" to { sink: EventChannel.EventSink? -> screenEventSink = sink },
            "kero_space/accessibility" to { sink: EventChannel.EventSink? -> accessibilityEventSink = sink },
            "kero_space/wake_word" to { sink: EventChannel.EventSink? -> wakeWordEventSink = sink },
            "kero_space/usage_stats" to { sink: EventChannel.EventSink? -> usageStatsEventSink = sink },
        ).forEach { (channelName, assign) ->
            EventChannel(messenger, channelName).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) = assign(events)
                    override fun onCancel(arguments: Any?) = assign(null)
                },
            )
        }

        MethodChannel(messenger, "kero_space/methods").setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val dur = call.argument<Int>("durationSeconds") ?: 0
                    OverlayManager.showOverlay(applicationContext, pkg, dur)
                    result.success(null)
                }
                "dismissOverlay" -> {
                    OverlayManager.dismissOverlay()
                    result.success(null)
                }
                "setBlacklistRules" -> {
                    val rulesJson = call.argument<String>("rulesJson") ?: "[]"
                    com.example.kero_space.telemetry.BlacklistPreferencesStore
                        .saveRulesJson(applicationContext, rulesJson)
                    result.success(null)
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
                else -> result.notImplemented()
            }
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private fun unregisterReceiverSafe(receiver: android.content.BroadcastReceiver?) {
        if (receiver == null) return
        try {
            unregisterReceiver(receiver)
        } catch (e: Exception) {
            Log.w(TAG, "Error unregistering receiver: ${e.message}")
        }
    }
}

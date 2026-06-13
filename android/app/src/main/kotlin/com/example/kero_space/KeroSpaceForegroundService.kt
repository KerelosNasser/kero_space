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

    private val TAG = "KeroSpaceFS"
    private val CHANNEL_ID = "kero_space_foreground_channel"
    private var flutterEngine: FlutterEngine? = null
    private var screenReceiver: KeroSpaceScreenReceiver? = null

    // Channels exposed to other components to emit events to Dart
    companion object {
        var screenEventSink: EventChannel.EventSink? = null
        var accessibilityEventSink: EventChannel.EventSink? = null
        var wakeWordEventSink: EventChannel.EventSink? = null
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Starting Kero Space Foreground Service")
        createNotificationChannel()
        startForegroundServiceWithNotification()

        // Initialize Headless Flutter Engine
        startFlutterEngine()

        // Register Screen Receiver
        screenReceiver = KeroSpaceScreenReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)

        // TODO: Start WakeWordService or bound it
        val wakeWordIntent = Intent(this, WakeWordService::class.java)
        startService(wakeWordIntent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Kero Space Omniscient Layer"
            val descriptionText = "Keeps background agents running"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startForegroundServiceWithNotification() {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Kero Space Active")
            .setContentText("Omniscient layer is monitoring...")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var serviceTypes = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                serviceTypes = serviceTypes or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            }
            startForeground(1, notification, serviceTypes)
        } else {
            startForeground(1, notification)
        }
    }

    private fun startFlutterEngine() {
        try {
            val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
            flutterLoader.startInitialization(applicationContext)
            flutterLoader.ensureInitializationComplete(applicationContext, null)

            flutterEngine = FlutterEngine(applicationContext)

            setupChannels()

            val appBundlePath = flutterLoader.findAppBundlePath()
            val entrypoint = DartExecutor.DartEntrypoint(appBundlePath, "backgroundMain")
            flutterEngine?.dartExecutor?.executeDartEntrypoint(entrypoint)
            
            Log.d(TAG, "FlutterEngine initialized and backgroundMain executed.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Headless Flutter Engine", e)
        }
    }

    private fun setupChannels() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            EventChannel(messenger, "kero_space/screen_events").setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        screenEventSink = events
                    }
                    override fun onCancel(arguments: Any?) {
                        screenEventSink = null
                    }
                }
            )

            EventChannel(messenger, "kero_space/accessibility").setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        accessibilityEventSink = events
                    }
                    override fun onCancel(arguments: Any?) {
                        accessibilityEventSink = null
                    }
                }
            )

            EventChannel(messenger, "kero_space/wake_word").setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        wakeWordEventSink = events
                    }
                    override fun onCancel(arguments: Any?) {
                        wakeWordEventSink = null
                    }
                }
            )

            MethodChannel(messenger, "kero_space/methods").setMethodCallHandler { call, result ->
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
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy")
        screenReceiver?.let { unregisterReceiver(it) }
        flutterEngine?.destroy()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    // Android 15 dataSync timeout handling
    override fun onTimeout(startId: Int) {
        Log.w(TAG, "Foreground Service onTimeout called (Android 15+ dataSync limit).")
        // Ideally we restart or fallback to just microphone
        stopSelf(startId)
    }

    private fun handleAgentToggle(agentId: String, enabled: Boolean) {
        when (agentId) {
            "wake_word" -> {
                val intent = Intent(this, WakeWordService::class.java)
                if (enabled) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
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

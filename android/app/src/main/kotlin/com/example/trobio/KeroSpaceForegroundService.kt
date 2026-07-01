package com.example.trobio

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

class KeroSpaceForegroundService : Service() {

    companion object {
        private const val TAG = "KeroSpaceFS"
        private const val CHANNEL_ID = "kero_space_foreground_channel"
        private const val FGS_NOTIFICATION_ID = 1

        /**
         * Sinks for the HEADLESS engine only (backgroundMain isolate).
         *
         * Architecture: Two separate Flutter engines run concurrently:
         *
         *   1. MAIN engine (MainActivity) — serves the UI isolate.
         *      Registers handlers on kero_space/... channels.
         *      These sinks are managed by MainActivity.setupEventChannels().
         *
         *   2. HEADLESS engine (KeroSpaceForegroundService) — serves backgroundMain.
         *      Registers handlers on kero_space/bg/... channels.
         *      These sinks are managed below.
         *
         * KeroSpaceScreenReceiver and KeroSpaceAccessibilityService push to BOTH sets
         * of sinks so events reach both the UI and the background isolate independently.
         *
         * WakeWordService pushes to the MAIN engine only — VoiceBloc in the UI
         * reacts to wake word events. The background isolate has no use for them.
         */
        @Volatile var isRunning = false

        @Volatile var bgScreenEventSink: EventChannel.EventSink? = null
        @Volatile var bgAccessibilityEventSink: EventChannel.EventSink? = null
        @Volatile var bgUsageStatsEventSink: EventChannel.EventSink? = null

        /**
         * Main-engine sinks — set by MainActivity.setupEventChannels().
         * The accessibility service and screen receiver read these to push to the UI.
         */
        @Volatile var screenEventSink: EventChannel.EventSink? = null
        @Volatile var accessibilityEventSink: EventChannel.EventSink? = null
        @Volatile var wakeWordEventSink: EventChannel.EventSink? = null
        @Volatile var usageStatsEventSink: EventChannel.EventSink? = null
    }

    private var flutterEngine: FlutterEngine? = null
    private var screenReceiver: KeroSpaceScreenReceiver? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val usageStatsReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val payload = intent?.getStringExtra("payload") ?: return
            Log.d(TAG, "USAGE_STATS_READY — forwarding to Dart sinks")
            // Push to both engines so the UI TelemetryBloc and the Isar background writer both get it.
            usageStatsEventSink?.success(payload)
            bgUsageStatsEventSink?.success(payload)
        }
    }

    // ─── Lifecycle ───────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        Log.d(TAG, "onCreate")
        createNotificationChannel()
        startForegroundWithNotification()
        registerReceivers()
        // Staggered init: Flutter engine (heavy) first, then WakeWordService
        // after the background engine is ready — prevents boot contention on
        // the main thread from simultaneous Service + FlutterLoader init.
        startFlutterEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        isRunning = false
        Log.d(TAG, "onDestroy")
        // Null all event sinks to prevent leaks when the service is torn down
        // without a clean StreamHandler.onCancel cycle (e.g. system force-stop).
        screenEventSink = null
        accessibilityEventSink = null
        wakeWordEventSink = null
        usageStatsEventSink = null
        bgScreenEventSink = null
        bgAccessibilityEventSink = null
        bgUsageStatsEventSink = null
        serviceScope.cancel()
        unregisterReceiverSafe(screenReceiver)
        unregisterReceiverSafe(usageStatsReceiver)
        flutterEngine?.destroy()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onTimeout(startId: Int) {
        Log.w(TAG, "FGS onTimeout (Android 15+ dataSync limit). Scheduling restart.")
        val restartIntent = Intent(this, KeroSpaceForegroundService::class.java)
        val pendingIntent = PendingIntent.getService(
            this, 0, restartIntent, PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + 5000, pendingIntent)
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
        val usageFilter = IntentFilter("com.example.trobio.USAGE_STATS_READY")

        ContextCompat.registerReceiver(this, screenReceiver, screenFilter, ContextCompat.RECEIVER_NOT_EXPORTED)
        ContextCompat.registerReceiver(this, usageStatsReceiver, usageFilter, ContextCompat.RECEIVER_NOT_EXPORTED)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Trobio Omniscient Layer",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Keeps background agents running" }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(channel)
        }
    }

    private fun startForegroundWithNotification() {
        val notification: Notification = androidx.core.app.NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Trobio Active")
            .setContentText("Omniscient layer is monitoring...")
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            var serviceTypes = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val hasMic = ContextCompat.checkSelfPermission(
                    this, android.Manifest.permission.RECORD_AUDIO,
                ) == PackageManager.PERMISSION_GRANTED
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
        serviceScope.launch {
            try {
                // Phase 1: FlutterLoader initialization (I/O heavy — disk + native libs).
                launch {
                    val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
                    flutterLoader.startInitialization(applicationContext)
                    flutterLoader.ensureInitializationComplete(applicationContext, null)
                }.join()

                // Phase 2: Schedule UsageStatsWorker early so the 15-min interval
                // starts counting from boot, not from first Dart toggle.
                scheduleUsageStatsWorker()

                // Phase 3: Small delay to let system UI settle before allocating
                // the FlutterEngine (which pins ~50 MB native memory).
                delay(250)

                withContext(Dispatchers.Main) {
                    // Phase 4: Create FlutterEngine + register channels.
                    flutterEngine = FlutterEngine(applicationContext)
                    setupBackgroundChannels()

                    val entrypoint = DartExecutor.DartEntrypoint(
                        FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                        "backgroundMain",
                    )
                    flutterEngine?.dartExecutor?.executeDartEntrypoint(entrypoint)
                    Log.d(TAG, "Headless FlutterEngine started — backgroundMain executing")

                    // Phase 5: Start WakeWordService after engine is initialized
                    // to spread boot-time service creation contention.
                    startWakeWordServiceIfPermitted()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialise Headless FlutterEngine", e)
                // Still attempt WakeWordService even if headless engine fails —
                // it only emits on the main-engine sink (set by MainActivity).
                withContext(Dispatchers.Main) {
                    startWakeWordServiceIfPermitted()
                }
            }
        }
    }

    private fun startWakeWordServiceIfPermitted() {
        val hasMic = ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
        if (hasMic) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(Intent(this, WakeWordService::class.java))
            } else {
                startService(Intent(this, WakeWordService::class.java))
            }
        } else {
            Log.w(TAG, "RECORD_AUDIO not granted — skipping WakeWordService startup")
        }
    }

    /**
     * Schedules the [UsageStatsWorker] if it hasn't been scheduled already.
     * Called from the staggered boot sequence to ensure usage stats collection
     * starts automatically without waiting for a Dart-side toggle.
     */
    private fun scheduleUsageStatsWorker() {
        try {
            val constraints = Constraints.Builder()
                .setRequiresBatteryNotLow(true)
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                .build()
            val workRequest = PeriodicWorkRequestBuilder<UsageStatsWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()
            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "UsageStatsWorker",
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest,
            )
            Log.d(TAG, "UsageStatsWorker scheduled (interval=15m)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule UsageStatsWorker", e)
        }
    }

    /**
     * Registers background-isolate-specific channels on the HEADLESS engine's messenger.
     *
     * Channel naming convention:
     *   - kero_space/...     → main engine (UI isolate) — registered in MainActivity
     *   - kero_space/bg/...  → headless engine (backgroundMain isolate) — registered here
     *
     * This separation ensures each engine's binary messenger only delivers events to its
     * own Dart isolate. Shared sinks between engines are NOT possible because each engine
     * has its own independent binary messenger.
     */
    @Suppress("UNUSED_ANONYMOUS_PARAMETER")
    private fun setupBackgroundChannels() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger ?: return

        // EventChannels — background isolate variants (kero_space/bg/*)
        // onCancel sets the sink to null and wraps in try-catch so that FlutterEngine
        // detach / hot-restart / isolate crash never leaves a dangling reference.
        val bgChannels = mapOf(
            "kero_space/bg/screen_events" to { s: EventChannel.EventSink? -> bgScreenEventSink = s },
            "kero_space/bg/accessibility" to { s: EventChannel.EventSink? -> bgAccessibilityEventSink = s },
            "kero_space/bg/usage_stats" to { s: EventChannel.EventSink? -> bgUsageStatsEventSink = s },
        )
        bgChannels.forEach { (channelName, assign) ->
            EventChannel(messenger, channelName).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        Log.d(TAG, "bg stream onListen — $channelName")
                        assign(events)
                    }

                    override fun onCancel(arguments: Any?) {
                        Log.d(TAG, "bg stream onCancel — $channelName")
                        try {
                            assign(null)
                        } catch (e: Exception) {
                            Log.e(TAG, "bg stream onCancel error — $channelName", e)
                        }
                    }
                },
            )
        }

        // MethodChannel — background isolate can request overlay/blacklist operations
        MethodChannel(messenger, "kero_space/bg/methods").setMethodCallHandler { call, result ->
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
                    com.example.trobio.telemetry.BlacklistPreferencesStore
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


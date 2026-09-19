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
import androidx.work.Worker
import androidx.work.WorkerParameters
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

        fun buildTelemetryHudNotification(context: Context): Notification {
            var unlocks = 0
            var timeStr = "0m"
            var content = "Tap to open Telemetry Dashboard"

            try {
                val prefs = context.getSharedPreferences("trobio_telemetry_hud", Context.MODE_PRIVATE)
                val todayStr = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())
                val lastDate = prefs.getString("last_date", "")
                unlocks = prefs.getInt("unlock_count", 0)

                if (lastDate != todayStr) {
                    unlocks = 0
                    prefs.edit().putString("last_date", todayStr).putInt("unlock_count", 0).apply()
                }

                val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager
                val calendar = java.util.Calendar.getInstance().apply {
                    set(java.util.Calendar.HOUR_OF_DAY, 0)
                    set(java.util.Calendar.MINUTE, 0)
                    set(java.util.Calendar.SECOND, 0)
                    set(java.util.Calendar.MILLISECOND, 0)
                }
                val startTime = calendar.timeInMillis
                val endTime = System.currentTimeMillis()

                var totalScreenTimeMs = 0L
                var topAppName = ""
                var topAppDurationMs = 0L

                val statsList = usageStatsManager?.queryUsageStats(
                    android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                    startTime,
                    endTime
                )

                if (!statsList.isNullOrEmpty()) {
                    val pm = context.packageManager
                    val validStats = statsList.filter {
                        it.packageName != context.packageName &&
                        !it.packageName.contains("launcher") &&
                        !it.packageName.contains("systemui") &&
                        it.totalTimeInForeground > 30000L
                    }

                    for (stat in statsList) {
                        if (stat.packageName != context.packageName && !stat.packageName.contains("systemui")) {
                            totalScreenTimeMs += stat.totalTimeInForeground
                        }
                    }

                    val topStat = validStats.maxByOrNull { it.totalTimeInForeground }
                    if (topStat != null) {
                        topAppDurationMs = topStat.totalTimeInForeground
                        topAppName = try {
                            val appInfo = pm.getApplicationInfo(topStat.packageName, 0)
                            pm.getApplicationLabel(appInfo).toString()
                        } catch (_: Exception) {
                            topStat.packageName.substringAfterLast('.')
                        }
                    }
                }

                val hours = (totalScreenTimeMs / (1000 * 60 * 60)).toInt()
                val minutes = ((totalScreenTimeMs / (1000 * 60)) % 60).toInt()
                timeStr = if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"

                val topAppMin = (topAppDurationMs / (1000 * 60)).toInt()
                val topAppHours = topAppMin / 60
                val topAppRemMin = topAppMin % 60
                val topAppTimeStr = if (topAppHours > 0) "${topAppHours}h ${topAppRemMin}m" else "${topAppMin}m"

                content = if (topAppName.isNotEmpty()) "Top: $topAppName ($topAppTimeStr)" else "Monitoring digital wellbeing"
            } catch (e: Exception) {
                Log.w(TAG, "Error building HUD notification: ${e.message}")
            }

            val title = "📱 $unlocks Unlocks Today • $timeStr Screen Time"

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                putExtra("NAVIGATE_TO", "telemetry")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = if (launchIntent != null) {
                PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else null

            val builder = androidx.core.app.NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(content)
                .setSmallIcon(R.drawable.ic_notification)
                .setOngoing(true)
                .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)
                .setStyle(
                    androidx.core.app.NotificationCompat.BigTextStyle()
                        .setBigContentTitle(title)
                        .bigText("$content\nTap to open Recovery & Telemetry Dashboard")
                )

            if (pendingIntent != null) {
                builder.setContentIntent(pendingIntent)
            }

            return builder.build()
        }

        fun updateLiveTelemetryNotification(context: Context) {
            try {
                val notification = buildTelemetryHudNotification(context)
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.notify(FGS_NOTIFICATION_ID, notification)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update HUD notification: ${e.message}")
            }
        }
    }

    private var flutterEngine: FlutterEngine? = null
    private var screenReceiver: KeroSpaceScreenReceiver? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val usageStatsReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val payload = intent?.getStringExtra("payload") ?: return
            Log.d(TAG, "USAGE_STATS_READY — forwarding to Dart sinks")
            usageStatsEventSink.safeSuccess(payload)
            bgUsageStatsEventSink.safeSuccess(payload)
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
        startFlutterEngine()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        isRunning = false
        Log.d(TAG, "onDestroy")
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
        try {
            val restartIntent = Intent(this, KeroSpaceForegroundService::class.java)
            val pendingIntent = PendingIntent.getForegroundService(
                this, 0, restartIntent, PendingIntent.FLAG_IMMUTABLE
            )
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        System.currentTimeMillis() + 5000,
                        pendingIntent
                    )
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + 5000, pendingIntent)
                }
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + 5000, pendingIntent)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not schedule alarm restart on timeout: ${e.message}")
        }

        try {
            val restartRequest = androidx.work.OneTimeWorkRequestBuilder<KeroSpaceRestartWorker>()
                .setInitialDelay(5, TimeUnit.SECONDS)
                .build()
            WorkManager.getInstance(applicationContext).enqueue(restartRequest)
        } catch (we: Exception) {
            Log.w(TAG, "WorkManager restart fallback could not be enqueued: ${we.message}")
        }

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
        val notification: Notification = buildTelemetryHudNotification(this)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                FGS_NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(FGS_NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
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
        // Android 14+ prohibits background services from launching a microphone FGS.
        // WakeWordService is deferred to foreground activity or explicit user toggle.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Log.d(TAG, "Android 14+: WakeWordService deferred to foreground UI to prevent background FGS crash")
            return
        }
        val hasMic = ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
        if (hasMic) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(Intent(this, WakeWordService::class.java))
                } else {
                    startService(Intent(this, WakeWordService::class.java))
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not start WakeWordService: ${e.message}")
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

/**
 * Worker invoked as fallback on Android 15/16 when FGS onTimeout triggers.
 * Safely restarts [KeroSpaceForegroundService] without violating background start restrictions.
 */
class KeroSpaceRestartWorker(appContext: Context, workerParams: WorkerParameters) :
    Worker(appContext, workerParams) {
    override fun doWork(): Result {
        Log.d("KeroSpaceRestartWorker", "Restarting KeroSpaceForegroundService from WorkManager")
        return try {
            val serviceIntent = Intent(applicationContext, KeroSpaceForegroundService::class.java)
            ContextCompat.startForegroundService(applicationContext, serviceIntent)
            Result.success()
        } catch (e: Exception) {
            Log.e("KeroSpaceRestartWorker", "Failed to restart KeroSpaceForegroundService", e)
            Result.retry()
        }
    }
}



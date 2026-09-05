package com.example.trobio

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Manages the decision-break and cooldown overlay window.
 *
 * Enforces thread safety, overlay permission validation, and fixes timer reset loops.
 */
object OverlayManager {

    private const val TAG = "OverlayManager"

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var titleTextView: TextView? = null
    private var subtitleTextView: TextView? = null
    private var countdownTextView: TextView? = null
    private var countDownTimer: CountDownTimer? = null

    private val overlayShowing = AtomicBoolean(false)
    private val lastBreakTakenMap = ConcurrentHashMap<String, Long>()

    @Volatile private var activePackageName: String? = null
    @Volatile private var recordBreakOnDismiss = true

    fun hasBreakBeenTakenRecently(packageName: String, cooldownMinutes: Int = 15): Boolean {
        val lastTime = lastBreakTakenMap[packageName] ?: 0L
        return System.currentTimeMillis() - lastTime < cooldownMinutes * 60 * 1000L
    }

    private fun recordBreakTaken(packageName: String) {
        lastBreakTakenMap[packageName] = System.currentTimeMillis()
    }

    fun isShowing(): Boolean = overlayShowing.get()

    fun getActivePackage(): String? = activePackageName

    fun showOverlay(
        context: Context,
        packageName: String,
        durationSeconds: Int,
        title: String = "Decision Break",
        subtitle: String = packageName,
        shouldRecordBreakOnDismiss: Boolean = true,
    ) {
        if (durationSeconds <= 0) {
            Log.w(TAG, "showOverlay called with durationSeconds=$durationSeconds — ignoring")
            return
        }

        val appContext = context.applicationContext

        mainHandler.post {
            // 1. Permission check
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(appContext)) {
                Log.w(TAG, "Overlay permission not granted. Cannot show overlay.")
                return@post
            }

            // 2. CRITICAL BUG FIX: If overlay is already active for this package, DO NOT restart the timer!
            if (overlayShowing.get() && activePackageName == packageName && countDownTimer != null) {
                return@post
            }

            if (overlayView == null) {
                if (!overlayShowing.compareAndSet(false, true)) {
                    if (activePackageName != packageName) {
                        Log.d(TAG, "Overlay already showing for another package — ignoring")
                    }
                    return@post
                }

                windowManager = appContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
                if (windowManager == null) {
                    Log.e(TAG, "WindowManager not available")
                    overlayShowing.set(false)
                    return@post
                }

                val layout = LinearLayout(appContext).apply {
                    orientation = LinearLayout.VERTICAL
                    setBackgroundColor(Color.parseColor("#E6000000"))
                    gravity = Gravity.CENTER
                    setPadding(64, 96, 64, 96)
                    isClickable = true
                    isFocusable = true
                }

                titleTextView = TextView(appContext).apply {
                    setTextColor(Color.WHITE)
                    textSize = 28f
                    gravity = Gravity.CENTER
                    setTypeface(typeface, android.graphics.Typeface.BOLD)
                }
                subtitleTextView = TextView(appContext).apply {
                    setTextColor(Color.parseColor("#CCFFFFFF"))
                    textSize = 18f
                    gravity = Gravity.CENTER
                }
                countdownTextView = TextView(appContext).apply {
                    setTextColor(Color.WHITE)
                    textSize = 42f
                    gravity = Gravity.CENTER
                    setTypeface(typeface, android.graphics.Typeface.BOLD)
                }

                layout.addView(titleTextView)
                layout.addView(subtitleTextView)
                layout.addView(countdownTextView)

                val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }

                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    layoutFlag,
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT,
                )

                try {
                    windowManager?.addView(layout, params)
                    overlayView = layout
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to add overlay view", e)
                    overlayShowing.set(false)
                    activePackageName = null
                    return@post
                }
            }

            activePackageName = packageName
            recordBreakOnDismiss = shouldRecordBreakOnDismiss
            titleTextView?.text = title
            subtitleTextView?.text = subtitle
            startTimer(durationSeconds, packageName)
            Log.d(TAG, "Overlay shown for $packageName (${durationSeconds}s)")
        }
    }

    private fun startTimer(durationSeconds: Int, packageName: String) {
        countDownTimer?.cancel()
        countdownTextView?.text = formatDuration(durationSeconds.toLong() * 1000L)
        countDownTimer = object : CountDownTimer(durationSeconds * 1000L, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                countdownTextView?.text = formatDuration(millisUntilFinished)
            }

            override fun onFinish() {
                countdownTextView?.text = "00:00"
                dismissOverlay(packageName, recordBreakOnDismiss)
            }
        }.start()
    }

    fun formatDuration(durationMs: Long): String {
        val totalSeconds = durationMs / 1000L
        val hours = totalSeconds / 3600L
        val minutes = (totalSeconds % 3600L) / 60L
        val seconds = totalSeconds % 60L
        return if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d", minutes, seconds)
        }
    }

    fun dismissOverlay(packageName: String? = null, shouldRecordBreak: Boolean = true) {
        mainHandler.post {
            countDownTimer?.cancel()
            countDownTimer = null
            val view = overlayView ?: run {
                overlayShowing.set(false)
                activePackageName = null
                return@post
            }
            try {
                windowManager?.removeView(view)
                Log.d(TAG, "Overlay dismissed")
                if (packageName != null && shouldRecordBreak) {
                    recordBreakTaken(packageName)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to remove overlay view", e)
            } finally {
                overlayView = null
                titleTextView = null
                subtitleTextView = null
                countdownTextView = null
                activePackageName = null
                overlayShowing.set(false)
            }
        }
    }
}

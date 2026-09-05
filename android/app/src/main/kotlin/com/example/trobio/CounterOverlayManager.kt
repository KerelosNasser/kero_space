package com.example.trobio

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

object CounterOverlayManager {

    private const val TAG = "CounterOverlay"
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var timeText: TextView? = null
    private var countDownTimer: CountDownTimer? = null
    
    @Volatile private var isShowing = false
    @Volatile private var currentTarget: String = ""

    @SuppressLint("ClickableViewAccessibility")
    fun showCounter(context: Context, target: String, timeRemainingMs: Long) {
        val appContext = context.applicationContext

        mainHandler.post {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(appContext)) {
                Log.w(TAG, "Overlay permission not granted. Cannot show counter overlay.")
                return@post
            }

            if (isShowing && currentTarget == target) {
                return@post // Let existing timer run
            }

            dismissCounterInternal()
            currentTarget = target

            windowManager = appContext.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            if (windowManager == null) {
                Log.e(TAG, "WindowManager not available for counter overlay")
                return@post
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.TOP or Gravity.START
            params.x = 0
            params.y = 300

            val layout = LinearLayout(appContext).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(40, 20, 40, 20)
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#E6000000"))
                    cornerRadius = 100f
                    setStroke(2, Color.parseColor("#4DFFFFFF"))
                }
            }

            timeText = TextView(appContext).apply {
                text = formatTime(timeRemainingMs)
                setTextColor(Color.WHITE)
                textSize = 16f
                setTypeface(null, android.graphics.Typeface.BOLD)
            }

            layout.addView(timeText)
            floatingView = layout

            var initialX = 0
            var initialY = 0
            var initialTouchX = 0f
            var initialTouchY = 0f

            layout.setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        try {
                            windowManager?.updateViewLayout(floatingView, params)
                        } catch (e: Exception) {
                            Log.w(TAG, "Error updating counter position: ${e.message}")
                        }
                        true
                    }
                    else -> false
                }
            }

            try {
                windowManager?.addView(floatingView, params)
                isShowing = true
                startTimer(timeRemainingMs)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add counter overlay", e)
                floatingView = null
                isShowing = false
            }
        }
    }

    private fun startTimer(timeMs: Long) {
        countDownTimer?.cancel()
        countDownTimer = object : CountDownTimer(timeMs, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                timeText?.text = formatTime(millisUntilFinished)
                if (millisUntilFinished < 60000) {
                    timeText?.setTextColor(Color.parseColor("#FF4C4C"))
                }
            }
            override fun onFinish() {
                timeText?.text = "00:00"
            }
        }.start()
    }

    fun formatTime(ms: Long): String {
        val totalSeconds = ms / 1000
        val m = totalSeconds / 60
        val s = totalSeconds % 60
        return String.format("%02d:%02d", m, s)
    }

    fun dismissCounter() {
        mainHandler.post {
            dismissCounterInternal()
        }
    }

    private fun dismissCounterInternal() {
        if (!isShowing && floatingView == null) return
        countDownTimer?.cancel()
        countDownTimer = null
        try {
            floatingView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to remove counter overlay", e)
        }
        floatingView = null
        isShowing = false
        currentTarget = ""
    }
}

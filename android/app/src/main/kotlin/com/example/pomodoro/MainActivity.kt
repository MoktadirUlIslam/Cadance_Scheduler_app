package com.example.pomodoro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Build
import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.LayoutInflater
import android.view.View
import android.view.Gravity
import android.widget.Button
import android.widget.TextView
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.Timer
import java.util.TimerTask
import android.graphics.PixelFormat
import android.os.PowerManager
import android.view.KeyEvent
import android.media.AudioAttributes
import android.os.VibrationEffect  // Added import

class MainActivity : FlutterActivity() {
    private val PHONE_LOCK_CHANNEL = "phone_lock"
    private val FORCED_RETURN_CHANNEL = "forced_return"

    // Overlay variables
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var mediaPlayer: MediaPlayer? = null
    private var timer: Timer? = null
    private var handler = Handler(Looper.getMainLooper())
    private var currentVolume = 0.3f
    private var countdown = 10
    private var isOverlayShowing = false
    private var isReturningFromOverlay = false
    private var isOverlayDismissed = false
    private var alarmStarted = false

    override fun onResume() {
        super.onResume()

        // Dismiss overlay when app resumes
        if (isOverlayShowing) {
            dismissOverlay()
            notifyFlutterUserReturned()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phone Lock Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_LOCK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableLock" -> {
                        enablePhoneLock()
                        result.success(true)
                    }
                    "disableLock" -> {
                        disablePhoneLock()
                        result.success(true)
                    }
                    "isLocked" -> {
                        result.success(isLockTaskModeEnabled())
                    }
                    else -> result.notImplemented()
                }
            }

        // Forced Return Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FORCED_RETURN_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showForcedReturn" -> {
                        val args = call.arguments as? Map<*, *>
                        showForcedReturnOverlay(args, result)
                    }
                    "dismissForcedReturn" -> {
                        dismissOverlay()
                        result.success(true)
                    }
                    "isOverlayShowing" -> {
                        result.success(isOverlayShowing)
                    }
                    "playAlarmSound" -> {
                        playAlarmSound()
                        result.success(true)
                    }
                    "stopAlarmSound" -> {
                        stopAlarmSound()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─── PHONE LOCK METHODS ───

    private fun enablePhoneLock() {
        runOnUiThread {
            try {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    try {
                        startLockTask()
                        Log.d("PhoneLock", "✅ Lock task mode enabled")
                    } catch (e: Exception) {
                        Log.e("PhoneLock", "Failed to enable lock task: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e("PhoneLock", "enablePhoneLock error: ${e.message}")
            }
        }
    }

    private fun disablePhoneLock() {
        runOnUiThread {
            try {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    try {
                        stopLockTask()
                        Log.d("PhoneLock", "✅ Lock task mode disabled")
                    } catch (e: Exception) {
                        Log.e("PhoneLock", "Failed to disable lock task: ${e.message}")
                    }
                }
            } catch (e: Exception) {
                Log.e("PhoneLock", "disablePhoneLock error: ${e.message}")
            }
        }
    }

    private fun isLockTaskModeEnabled(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            return try {
                activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
            } catch (e: Exception) {
                false
            }
        }
        return false
    }

    override fun onBackPressed() {
        if (isLockTaskModeEnabled()) {
            return
        }
        super.onBackPressed()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        // Block home button when overlay is showing
        if (isOverlayShowing && (keyCode == KeyEvent.KEYCODE_HOME ||
                    keyCode == KeyEvent.KEYCODE_APP_SWITCH)) {
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    // ─── FORCED RETURN OVERLAY METHODS ───

    private fun showForcedReturnOverlay(args: Map<*, *>?, result: MethodChannel.Result) {
        try {
            if (isOverlayShowing) {
                dismissOverlay()
            }

            val title = args?.get("title") as? String ?: "⚠️ BREAK ENDING!"
            val subtitle = args?.get("subtitle") as? String ?: "Return to app now!"
            val countdownSeconds = args?.get("countdown") as? Int ?: 10
            val playAlarm = args?.get("alarmSound") as? Boolean ?: true

            // Check overlay permission for Android 6+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (!Settings.canDrawOverlays(this)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        android.net.Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.error("PERMISSION_DENIED", "Overlay permission needed", null)
                    return
                }
            }

            showOverlay(title, subtitle, countdownSeconds, playAlarm)
            isOverlayShowing = true
            isOverlayDismissed = false
            Log.d("ForcedReturn", "✅ Overlay shown")

            result.success(true)
        } catch (e: Exception) {
            Log.e("ForcedReturn", "showForcedReturnOverlay error: ${e.message}")
            result.error("OVERLAY_ERROR", e.message, null)
        }
    }

    private fun showOverlay(title: String, subtitle: String, countdownSeconds: Int, playAlarm: Boolean) {
        runOnUiThread {
            try {
                // Get window manager
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

                // Inflate overlay layout
                val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
                overlayView = inflater.inflate(R.layout.overlay_forced_return, null)

                // Set up text
                val titleView = overlayView?.findViewById<TextView>(R.id.overlay_title)
                val subtitleView = overlayView?.findViewById<TextView>(R.id.overlay_subtitle)
                val countdownView = overlayView?.findViewById<TextView>(R.id.overlay_countdown)
                val returnButton = overlayView?.findViewById<Button>(R.id.overlay_return_button)
                // REMOVED: statusText - not needed

                titleView?.text = title
                subtitleView?.text = subtitle
                countdownView?.text = countdownSeconds.toString()

                // Return button
                returnButton?.setOnClickListener {
                    Log.d("ForcedReturn", "👆 User clicked Return to App!")
                    onUserReturned()
                }

                // Create layout parameters with improved visibility
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    } else {
                        WindowManager.LayoutParams.TYPE_PHONE
                    },
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
                            or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
                            or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                            or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                            or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                            or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                            or WindowManager.LayoutParams.FLAG_FULLSCREEN,
                    PixelFormat.TRANSLUCENT
                )

                params.gravity = Gravity.CENTER

                windowManager?.addView(overlayView, params)
                Log.d("ForcedReturn", "✅ Overlay view added to window")

                // Start alarm and countdown
                if (playAlarm) {
                    playAlarmSound()
                    startVolumeIncrease()
                    startCountdown(countdownSeconds)
                    alarmStarted = true
                }

                // Show notification in status bar
                showOverlayNotification(title)

            } catch (e: Exception) {
                Log.e("ForcedReturn", "showOverlay error: ${e.message}")
            }
        }
    }

    private fun playAlarmSound() {
        try {
            // Release any existing player
            stopAlarmSound()

            // Create new media player with alarm sound
            mediaPlayer = MediaPlayer().apply {
                // Use default alarm sound
                val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)

                if (alarmUri != null) {
                    setDataSource(this@MainActivity, alarmUri)
                } else {
                    // Fallback: Use notification sound if alarm not available
                    val notificationUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    if (notificationUri != null) {
                        setDataSource(this@MainActivity, notificationUri)
                    } else {
                        // Last resort: Use a built-in sound
                        val fallbackUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                        if (fallbackUri != null) {
                            setDataSource(this@MainActivity, fallbackUri)
                        }
                    }
                }

                // Set audio attributes
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .build()
                    )
                } else {
                    @Suppress("DEPRECATION")
                    setAudioStreamType(AudioManager.STREAM_ALARM)
                }

                // Start with low volume
                currentVolume = 0.3f
                setVolume(currentVolume, currentVolume)
                isLooping = true
                prepare()
                start()

                Log.d("ForcedReturn", "🔊 Alarm started at ${(currentVolume * 100).toInt()}% volume")
            }
        } catch (e: Exception) {
            Log.e("ForcedReturn", "playAlarmSound error: ${e.message}")
            // Try fallback with ringtone
            try {
                playFallbackSound()
            } catch (e2: Exception) {
                Log.e("ForcedReturn", "Fallback sound also failed: ${e2.message}")
            }
        }
    }

    private fun playFallbackSound() {
        try {
            mediaPlayer = MediaPlayer.create(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE))
            mediaPlayer?.apply {
                setVolume(0.5f, 0.5f)
                isLooping = true
                start()
                Log.d("ForcedReturn", "🔊 Fallback ringtone started")
            }
        } catch (e: Exception) {
            Log.e("ForcedReturn", "playFallbackSound error: ${e.message}")
        }
    }

    private fun stopAlarmSound() {
        try {
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            mediaPlayer = null
            alarmStarted = false
            Log.d("ForcedReturn", "🔇 Alarm stopped")
        } catch (e: Exception) {
            Log.e("ForcedReturn", "stopAlarmSound error: ${e.message}")
        }
    }

    private fun startVolumeIncrease() {
        timer = Timer()
        timer?.schedule(object : TimerTask() {
            override fun run() {
                handler.post {
                    if (isOverlayShowing && !isOverlayDismissed) {
                        if (currentVolume < 1.0f) {
                            currentVolume += 0.05f
                            if (currentVolume > 1.0f) currentVolume = 1.0f
                            mediaPlayer?.setVolume(currentVolume, currentVolume)
                            Log.d("ForcedReturn", "🔊 Volume increased to ${(currentVolume * 100).toInt()}%")
                        }
                    } else {
                        // Stop volume increase if overlay is dismissed
                        timer?.cancel()
                        timer = null
                    }
                }
            }
        }, 1000, 1000) // Increase every second
    }

    private fun startCountdown(countdownSeconds: Int) {
        countdown = countdownSeconds
        val countdownView = overlayView?.findViewById<TextView>(R.id.overlay_countdown)

        timer?.schedule(object : TimerTask() {
            override fun run() {
                handler.post {
                    if (isOverlayShowing && !isOverlayDismissed) {
                        countdown--
                        if (countdown <= 0) {
                            countdownView?.text = "⏰ NOW!"
                            mediaPlayer?.setVolume(1.0f, 1.0f)
                            Log.d("ForcedReturn", "⏰ Countdown ended! MAX VOLUME!")

                            // Vibrate if possible
                            vibrateDevice()
                        } else {
                            countdownView?.text = countdown.toString()
                        }
                    } else {
                        timer?.cancel()
                        timer = null
                    }
                }
            }
        }, 1000, 1000)
    }

    private fun vibrateDevice() {
        try {
            val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator?
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Fixed: Use VibrationEffect.createOneShot instead of createPattern
                vibrator?.vibrate(
                    VibrationEffect.createOneShot(1000, VibrationEffect.DEFAULT_AMPLITUDE)
                )
                // Or for pattern vibration:
                // vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 500, 500), 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(1000) // Simple vibration for older devices
            }
            Log.d("ForcedReturn", "📳 Vibration started")
        } catch (e: Exception) {
            Log.e("ForcedReturn", "Vibrate error: ${e.message}")
        }
    }

    private fun showOverlayNotification(title: String) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                val channelId = "forced_return_channel"
                val channelName = "Forced Return Alerts"

                val channel = android.app.NotificationChannel(
                    channelId,
                    channelName,
                    android.app.NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alerts for forced return overlay"
                    enableVibration(true)
                    enableLights(true)
                }
                notificationManager.createNotificationChannel(channel)

                val notification = android.app.Notification.Builder(this, channelId)
                    .setContentTitle("⏰ Break Time Over!")
                    .setContentText("Return to app now!")
                    .setSmallIcon(android.R.drawable.ic_dialog_alert)
                    .setPriority(android.app.Notification.PRIORITY_HIGH)
                    .build()

                notificationManager.notify(1001, notification)
                Log.d("ForcedReturn", "📢 Notification shown")
            }
        } catch (e: Exception) {
            Log.e("ForcedReturn", "Notification error: ${e.message}")
        }
    }

    private fun onUserReturned() {
        Log.d("ForcedReturn", "👆 User returned! Dismissing overlay...")

        if (isReturningFromOverlay) return
        isReturningFromOverlay = true

        dismissOverlay()
        bringAppToForeground()
        notifyFlutterUserReturned()

        handler.postDelayed({
            isReturningFromOverlay = false
        }, 1000)
    }

    private fun bringAppToForeground() {
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(intent)
            Log.d("ForcedReturn", "✅ App brought to foreground")
        } catch (e: Exception) {
            Log.e("ForcedReturn", "bringAppToForeground error: ${e.message}")
        }
    }

    private fun notifyFlutterUserReturned() {
        try {
            val channel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger!!,
                FORCED_RETURN_CHANNEL
            )
            channel.invokeMethod("userReturnedToApp", null)
            Log.d("ForcedReturn", "✅ Flutter notified: user returned")
        } catch (e: Exception) {
            Log.e("ForcedReturn", "notifyFlutterUserReturned error: ${e.message}")
        }
    }

    private fun dismissOverlay() {
        try {
            isOverlayDismissed = true

            // Cancel timer
            timer?.cancel()
            timer = null

            // Stop alarm
            stopAlarmSound()

            // Remove overlay view
            overlayView?.let { view ->
                try {
                    windowManager?.removeView(view)
                    Log.d("ForcedReturn", "✅ Overlay view removed")
                } catch (e: Exception) {
                    Log.e("ForcedReturn", "Error removing overlay: ${e.message}")
                }
            }

            windowManager = null
            overlayView = null
            isOverlayShowing = false
            currentVolume = 0.3f
            alarmStarted = false

            Log.d("ForcedReturn", "✅ Overlay dismissed")
        } catch (e: Exception) {
            Log.e("ForcedReturn", "dismissOverlay error: ${e.message}")
        }
    }

    override fun onDestroy() {
        dismissOverlay()
        super.onDestroy()
    }

    // Add this to handle screen wake
    private fun wakeScreen() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "ForcedReturnWakeLock"
            )
            wakeLock.acquire(10000) // Release after 10 seconds
        } catch (e: Exception) {
            Log.e("ForcedReturn", "Wake screen error: ${e.message}")
        }
    }
}
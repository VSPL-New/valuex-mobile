package com.valuex.valuex_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannels()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "begin" -> {
                        beginCall(call.argument<Boolean>("video") ?: false)
                        result.success(null)
                    }
                    "end" -> {
                        endCall()
                        result.success(null)
                    }
                    "startRinging" -> {
                        startRinging(call.argument<Boolean>("incoming") ?: false)
                        result.success(null)
                    }
                    "stopRinging" -> {
                        stopRinging()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** A call is on (US-014, US-015): the screen stays awake and the media keeps running in the background. */
    private fun beginCall(video: Boolean) {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val service = Intent(this, CallForegroundService::class.java)
            .putExtra(CallForegroundService.EXTRA_VIDEO, video)
        try {
            startForegroundService(service)
        } catch (e: RuntimeException) {
            // The call goes on while the app is on screen; only its background keep-alive is lost.
        }
    }

    private fun endCall() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        stopService(Intent(this, CallForegroundService::class.java))
    }

    private var ringtone: Ringtone? = null
    private var ringback: ToneGenerator? = null

    /**
     * A call waits for an answer (US-014, US-015): the phone's ringtone with vibration for an incoming call, the
     * ringback tone for the caller. It follows the phone's ringer mode and volume, and never throws.
     */
    private fun startRinging(incoming: Boolean) {
        stopRinging()
        try {
            if (incoming) {
                val ringer = getSystemService(AudioManager::class.java)
                if (ringer == null || ringer.ringerMode == AudioManager.RINGER_MODE_NORMAL) {
                    ringtone = RingtoneManager.getRingtone(this, RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE))
                        ?.apply {
                            audioAttributes = AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) isLooping = true
                            play()
                        }
                }
                vibrate(true)
            } else {
                ringback = ToneGenerator(AudioManager.STREAM_VOICE_CALL, RINGBACK_VOLUME).also {
                    it.startTone(ToneGenerator.TONE_SUP_RINGTONE)
                }
            }
        } catch (e: RuntimeException) {
            // A call without a sound is better than no call.
        }
    }

    private fun stopRinging() {
        try {
            ringtone?.stop()
            ringback?.stopTone()
            ringback?.release()
        } catch (e: RuntimeException) {
            // Already stopped.
        }
        ringtone = null
        ringback = null
        vibrate(false)
    }

    private fun vibrate(on: Boolean) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return
        if (!on) {
            vibrator.cancel()
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 800), 0))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(longArrayOf(0, 800, 800), 0)
        }
    }

    override fun onDestroy() {
        stopRinging()
        super.onDestroy()
    }

    /**
     * The channels the server names in a push (US-131). Android 8 and later need them to exist before a push
     * arrives, so they are made at every start; making one again changes nothing the person set.
     */
    private fun createPushChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val importance = NotificationManager.IMPORTANCE_DEFAULT
        val calls = NotificationChannel(
            "calls", getString(R.string.push_channel_calls), NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        manager.createNotificationChannels(
            listOf(
                NotificationChannel("chat", getString(R.string.push_channel_chat), importance),
                NotificationChannel("offers", getString(R.string.push_channel_offers), importance),
                NotificationChannel("general", getString(R.string.push_channel_general), importance),
                calls,
            ),
        )
    }

    private companion object {
        const val CALL_CHANNEL = "com.valuex.valuex_mobile/call"
        const val RINGBACK_VOLUME = 70
    }
}

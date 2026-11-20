package com.valuex.valuex_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannels()
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
}

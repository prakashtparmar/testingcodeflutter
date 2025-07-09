package com.example.snap_check

import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat

class BackgroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when(intent?.action) {
            "START" -> {
                val notification = NotificationCompat.Builder(this, "location_tracker")
                    .setContentTitle("Location Tracking")
                    .setContentText("Tracking your location in background")
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setOngoing(true)
                    .build()

                startForeground(1, notification)
            }
            "STOP" -> {
                stopForeground(true)
                stopSelf()
            }
        }
        return START_STICKY
    }
}
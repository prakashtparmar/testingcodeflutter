package com.example.snap_check

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL_ID = "location_tracker"
        private const val METHOD_CHANNEL = "location_tracker"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Handle deep links or other special intents here
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup MethodChannel for Flutter communication
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundService" -> {
                    try {
                        startBackgroundService()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting background service", e)
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "stopBackgroundService" -> {
                    try {
                        stopBackgroundService()
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error stopping background service", e)
                        result.error("SERVICE_ERROR", e.message, null)
                    }
                }
                "checkLocationPermissions" -> {
                    result.success(checkLocationPermissions())
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        createNotificationChannel()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        try {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Location Tracker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Tracks your location in background"
                setShowBadge(false)
                // For Android 8.0+, set importance to low to prevent sound/vibration
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        } catch (e: Exception) {
            Log.e(TAG, "Error creating notification channel", e)
        }
    }

    private fun startBackgroundService() {
        try {
            val intent = Intent(this, BackgroundService::class.java).apply {
                action = "START"
            }
            ContextCompat.startForegroundService(this, intent)
            Log.d(TAG, "Background service started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting background service", e)
            throw e
        }
    }

    private fun stopBackgroundService() {
        try {
            val intent = Intent(this, BackgroundService::class.java).apply {
                action = "STOP"
            }
            startService(intent)
            Log.d(TAG, "Background service stop requested")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping background service", e)
            throw e
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Consider whether you want to stop the service here
        // Typically better to let it run unless explicitly stopped
    }

    fun checkLocationPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val fineLocation = checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION) ==
                    android.content.pm.PackageManager.PERMISSION_GRANTED
            val backgroundLocation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                checkSelfPermission(android.Manifest.permission.ACCESS_BACKGROUND_LOCATION) ==
                        android.content.pm.PackageManager.PERMISSION_GRANTED
            } else {
                true // Background permission not required before Android 10
            }
            fineLocation && backgroundLocation
        } else {
            true // Permissions granted by default before Android 6.0
        }
    }

    fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error opening battery optimization settings", e)
            }
        }
    }
}
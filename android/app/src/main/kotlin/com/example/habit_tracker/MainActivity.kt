package com.example.habit_tracker

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PERMISSIONS_CHANNEL = "com.habit_tracker/permissions"
    private val TIMER_CHANNEL = "com.habit_tracker/timer"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Request notification permission for Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    1
                )
            }
        }
        
        // Permissions channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "isOverlayPermissionGranted" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                "isIgnoringBatteryOptimization" -> {
                    val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                    val packageName = packageName
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Timer service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    val habitName = call.argument<String>("habitName") ?: ""
                    val elapsedSeconds = call.argument<Int>("elapsedSeconds") ?: 0
                    startForegroundService(habitName, elapsedSeconds)
                    result.success(true)
                }
                "updateForegroundService" -> {
                    val habitName = call.argument<String>("habitName") ?: ""
                    val elapsedTime = call.argument<String>("elapsedTime") ?: ""
                    updateForegroundService(habitName, elapsedTime)
                    result.success(true)
                }
                "stopForegroundService" -> {
                    stopForegroundService()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startForegroundService(habitName: String, elapsedSeconds: Int) {
        val intent = Intent(this, TimerForegroundService::class.java)
        intent.action = "START"
        intent.putExtra("habitName", habitName)
        intent.putExtra("elapsedSeconds", elapsedSeconds)
        startForegroundService(intent)
    }
    
    private fun updateForegroundService(habitName: String, elapsedTime: String) {
        val intent = Intent(this, TimerForegroundService::class.java)
        intent.action = "UPDATE"
        intent.putExtra("habitName", habitName)
        intent.putExtra("elapsedTime", elapsedTime)
        startService(intent)
    }
    
    private fun stopForegroundService() {
        val intent = Intent(this, TimerForegroundService::class.java)
        intent.action = "STOP"
        startService(intent)
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivityForResult(intent, 1)
            }
        }
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            val packageName = packageName
            
            if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }
}

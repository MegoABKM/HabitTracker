package com.example.habit_tracker;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;

public class TimerForegroundService extends Service {
    private static final int NOTIFICATION_ID = 1;
    private static final String CHANNEL_ID = "timer_channel";
    private Handler handler;
    private Runnable runnable;
    private int elapsedSeconds = 0;
    private String habitName = "";
    private boolean isRunning = false;

    @Override
    public void onCreate() {
        super.onCreate();
        handler = new Handler(Looper.getMainLooper());
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String action = intent.getAction();
            
            if ("START".equals(action)) {
                habitName = intent.getStringExtra("habitName");
                elapsedSeconds = intent.getIntExtra("elapsedSeconds", 0);
                startTimer();
            } else if ("STOP".equals(action)) {
                stopTimer();
                stopForeground(true);
                stopSelf();
            } else if ("UPDATE".equals(action)) {
                String elapsedTime = intent.getStringExtra("elapsedTime");
                if (elapsedTime != null) {
                    updateNotification(elapsedTime);
                }
            }
        }

        return START_STICKY;
    }

    private void startTimer() {
        if (isRunning) return;
        
        isRunning = true;
        createNotificationChannel();
        
        // Start foreground service with initial notification
        startForeground(NOTIFICATION_ID, createNotification());
        
        // Update notification every second
        runnable = new Runnable() {
            @Override
            public void run() {
                elapsedSeconds++;
                updateNotification();
                handler.postDelayed(this, 1000); // Update every 1 second
            }
        };
        handler.post(runnable);
    }

    private void stopTimer() {
        if (!isRunning) return;
        
        isRunning = false;
        handler.removeCallbacks(runnable);
    }

    private void updateNotification(String formattedTime) {
        // Update notification with new time
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, createNotification(formattedTime));
        }
    }
    
    private Notification createNotification(String customTime) {
        // Intent for opening app
        Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );
        
        // Intent for stop action
        Intent stopIntent = new Intent(this, TimerForegroundService.class);
        stopIntent.setAction("STOP");
        PendingIntent stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        return new Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Timer: " + customTime)
            .setContentText("Tracking: " + habitName)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true) // Don't vibrate/sound on updates
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build();
    }

    private Notification createNotification() {
        String formattedTime = formatTime(elapsedSeconds);
        
        // Intent for opening app
        Intent intent = getPackageManager().getLaunchIntentForPackage(getPackageName());
        PendingIntent pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );
        
        // Intent for stop action
        Intent stopIntent = new Intent(this, TimerForegroundService.class);
        stopIntent.setAction("STOP");
        PendingIntent stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        return new Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Timer: " + formattedTime)
            .setContentText("Tracking: " + habitName)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true) // Don't vibrate/sound on updates
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build();
    }

    private void updateNotification() {
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, createNotification());
        }
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Timer Notifications",
                NotificationManager.IMPORTANCE_LOW // Low importance = no vibration
            );
            channel.setDescription("Notifications for running timers");
            channel.setShowBadge(false);
            channel.enableVibration(false);
            channel.enableLights(false);
            channel.setSound(null, null);
            
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private String formatTime(int totalSeconds) {
        int hours = totalSeconds / 3600;
        int minutes = (totalSeconds % 3600) / 60;
        int seconds = totalSeconds % 60;

        if (hours > 0) {
            return String.format("%02d:%02d:%02d", hours, minutes, seconds);
        } else {
            return String.format("%02d:%02d", minutes, seconds);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopTimer();
    }
}


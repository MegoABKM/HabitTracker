package com.example.habit_tracker;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        // This will be called when the device boots up
        // For now, we don't need to start any service automatically
        // The notification system will handle timer state
    }
}


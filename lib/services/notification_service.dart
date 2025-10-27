import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel(
    'com.habit_tracker/timer',
  );
  static bool _isInitialized = false;

  /// Initialize background service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  /// Start timer - Use native foreground service
  static Future<void> startTimer({
    required String habitName,
    required int elapsedSeconds,
  }) async {
    await initialize();

    // Start foreground service via native code
    await _channel.invokeMethod('startForegroundService', {
      'habitName': habitName,
      'elapsedSeconds': elapsedSeconds,
    });
  }

  /// Stop timer
  static Future<void> stopTimer() async {
    await _channel.invokeMethod('stopForegroundService');
  }

  /// Show timer notification (legacy compatibility)
  static Future<void> showTimerNotification({
    required String habitName,
    required String elapsedTime,
  }) async {
    final seconds = _parseSecondsFromTime(elapsedTime);
    await startTimer(habitName: habitName, elapsedSeconds: seconds);
  }

  /// Update timer notification
  static Future<void> updateTimerNotification({
    required String habitName,
    required String elapsedTime,
  }) async {
    await initialize();

    // Update notification via native service
    await _channel.invokeMethod('updateForegroundService', {
      'habitName': habitName,
      'elapsedTime': elapsedTime,
    });
  }

  /// Cancel timer notification
  static Future<void> cancelTimerNotification() async {
    await stopTimer();
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await stopTimer();
  }

  /// Parse seconds from time string (MM:SS or HH:MM:SS)
  static int _parseSecondsFromTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return minutes * 60 + seconds;
      } else if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return hours * 3600 + minutes * 60 + seconds;
      }
    } catch (e) {
      // Parse error
    }
    return 0;
  }
}

import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static int _currentSeconds = 0;
  static String _currentHabitName = '';

  /// Initialize background service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final service = FlutterBackgroundService();

    // Configure Android
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'timer_channel',
        initialNotificationTitle: 'Habit Timer',
        initialNotificationContent: 'Timer running',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    _isInitialized = true;
  }

  /// Background task handler
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Initialize local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      InitializationSettings(android: android),
    );

    // Listen for start command
    service.on('startTimer').listen((event) {
      _currentHabitName = event?['habitName'] ?? 'Unknown';
      _currentSeconds = event?['elapsedSeconds'] ?? 0;
      updateNotification(service);
    });

    // Listen for stop command
    service.on('stopTimer').listen((event) {
      service.stopSelf();
    });

    // Timer loop
    Timer? periodicTimer;
    periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _currentSeconds++;
      await updateNotification(service);
    });

    service.on('stopService').listen((event) {
      periodicTimer?.cancel();
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  /// Update notification
  static Future<void> updateNotification(ServiceInstance service) async {
    final time = formatTime(_currentSeconds);

    const androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer Notifications',
      channelDescription: 'Shows timer progress',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      888,
      'Timer: $time',
      'Tracking: $_currentHabitName',
      details,
      payload: 'timer',
    );

    // Update foreground service notification for Android
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }
  }

  /// Format time to MM:SS or HH:MM:SS
  static String formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Start timer
  static Future<void> startTimer({
    required String habitName,
    required int elapsedSeconds,
  }) async {
    await initialize();

    final service = FlutterBackgroundService();
    service.invoke('startTimer', {
      'habitName': habitName,
      'elapsedSeconds': elapsedSeconds,
    });

    service.startService();
  }

  /// Stop timer
  static Future<void> stopTimer() async {
    final service = FlutterBackgroundService();
    service.invoke('stopTimer');
  }

  /// Legacy methods
  static Future<void> showTimerNotification({
    required String habitName,
    required String elapsedTime,
  }) async {
    final seconds = _parseSecondsFromTime(elapsedTime);
    await startTimer(habitName: habitName, elapsedSeconds: seconds);
  }

  static Future<void> updateTimerNotification({
    required String habitName,
    required String elapsedTime,
  }) async {
    // Updated automatically by background service
  }

  static Future<void> cancelTimerNotification() async {
    await stopTimer();
  }

  static Future<void> cancelAll() async {
    await stopTimer();
  }

  /// Parse seconds from time string
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

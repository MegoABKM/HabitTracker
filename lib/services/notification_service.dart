import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class NotificationService {
  @pragma('vm:entry-point')
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  @pragma('vm:entry-point')
  static bool _isInitialized = false;
  @pragma('vm:entry-point')
  static int _currentSeconds = 0;
  @pragma('vm:entry-point')
  static String _currentHabitName = '';
  @pragma('vm:entry-point')
  static int? _currentHabitId; // FIX: Add habit ID to track in the background

  /// Initialize background service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('DEBUG: Initializing background service...');

      // Initialize local notifications first
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: android),
      );
      print('DEBUG: Local notifications initialized');

      final service = FlutterBackgroundService();

      // Configure Android with simpler notification setup
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: false,
          isForegroundMode: false, // Start as background service first
          notificationChannelId: 'timer_channel',
          initialNotificationTitle: 'Habit Timer',
          initialNotificationContent: 'Timer service ready',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: onStart,
          onBackground: onIosBackground,
        ),
      );

      print('DEBUG: Background service configured successfully');
      _isInitialized = true;
    } catch (e) {
      print('ERROR: Failed to initialize background service: $e');
      rethrow;
    }
  }

  /// Background task handler
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('DEBUG: Background service onStart called');

    try {
      // Initialize local notifications in background isolate
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotifications.initialize(
        const InitializationSettings(android: android),
      );
      print('DEBUG: Local notifications initialized in background');

      // Create notification channel immediately
      await _createNotificationChannel();
      print('DEBUG: Notification channel created');

      Timer? periodicTimer;

      // Listen for start command
      service.on('startTimer').listen((event) {
        print('DEBUG: Received startTimer event: $event');
        try {
          // Cancel any existing timer before starting a new one
          periodicTimer?.cancel();

          _currentHabitName = event?['habitName'] ?? 'Unknown';
          _currentSeconds = event?['elapsedSeconds'] ?? 0;
          _currentHabitId = event?['habitId'];

          print(
            'DEBUG: Starting timer for habit: $_currentHabitName, seconds: $_currentSeconds',
          );

          // Show initial notification immediately and set as foreground
          updateNotification(service);

          // Set as foreground service after notification is created
          if (service is AndroidServiceInstance) {
            try {
              service.setAsForegroundService();
              print('DEBUG: Service set as foreground');
            } catch (e) {
              print('ERROR: Failed to set as foreground service: $e');
            }
          }

          // Timer loop
          periodicTimer = Timer.periodic(const Duration(seconds: 1), (
            timer,
          ) async {
            try {
              _currentSeconds++;
              await updateNotification(service);

              // Send update back to UI
              service.invoke('update', {
                'habitId': _currentHabitId,
                'seconds': _currentSeconds,
              });
            } catch (e) {
              print('ERROR: Timer loop failed: $e');
            }
          });

          print('DEBUG: Timer started successfully');
        } catch (e) {
          print('ERROR: Failed to start timer: $e');
        }
      });

      // Listen for stop command
      service.on('stopTimer').listen((event) {
        print('DEBUG: Received stopTimer event');
        try {
          periodicTimer?.cancel();
          _currentHabitId = null;
          service.stopSelf();
          print('DEBUG: Timer stopped successfully');
        } catch (e) {
          print('ERROR: Failed to stop timer: $e');
        }
      });

      print('DEBUG: Background service setup completed');
    } catch (e) {
      print('ERROR: Background service onStart failed: $e');
    }
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  /// Create notification channel
  @pragma('vm:entry-point')
  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'timer_channel',
      'Timer Notifications',
      description: 'Shows timer progress',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
    );

    // This creates the channel if it doesn't exist
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Update notification
  @pragma('vm:entry-point')
  static Future<void> updateNotification(ServiceInstance service) async {
    try {
      final time = formatTime(_currentSeconds);
      print(
        'DEBUG: Updating notification - Time: $time, Habit: $_currentHabitName',
      );

      const androidDetails = AndroidNotificationDetails(
        'timer_channel',
        'Timer Notifications',
        channelDescription: 'Shows timer progress',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        enableVibration: false,
        playSound: false,
        onlyAlertOnce: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        888,
        'Timer: $time',
        'Tracking: $_currentHabitName',
        details,
        payload: 'timer',
      );

      print('DEBUG: Notification updated successfully');

      // Update foreground service notification for Android
      if (service is AndroidServiceInstance) {
        try {
          service.setForegroundNotificationInfo(
            title: 'Timer: $time',
            content: 'Tracking: $_currentHabitName',
          );
          print('DEBUG: Foreground service notification updated');
        } catch (e) {
          print('ERROR: Failed to update foreground notification: $e');
        }
      }
    } catch (e) {
      print('ERROR: Failed to update notification: $e');
    }
  }

  /// Format time to MM:SS or HH:MM:SS
  @pragma('vm:entry-point')
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
    required int habitId,
    required String habitName,
    required int elapsedSeconds,
  }) async {
    try {
      print('DEBUG: Starting timer for habit: $habitName (ID: $habitId)');
      await initialize();

      final service = FlutterBackgroundService();

      // Start service if not running
      if (!await service.isRunning()) {
        print('DEBUG: Service not running, starting service...');
        await service.startService();
        // Wait a bit for service to start
        await Future.delayed(const Duration(milliseconds: 1000));
        print('DEBUG: Service started, waiting completed');
      } else {
        print('DEBUG: Service already running');
      }

      print(
        'DEBUG: Invoking startTimer with data: habitId=$habitId, habitName=$habitName, elapsedSeconds=$elapsedSeconds',
      );
      service.invoke('startTimer', {
        'habitId': habitId,
        'habitName': habitName,
        'elapsedSeconds': elapsedSeconds,
      });

      print('DEBUG: Timer start command sent successfully');
    } catch (e) {
      print('ERROR: Failed to start timer: $e');
      rethrow;
    }
  }

  /// Stop timer
  static Future<void> stopTimer() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopTimer');
    }
  }

  /// Legacy methods (Now just wrappers)
  static Future<void> showTimerNotification({
    required int habitId, // FIX: Add habitId
    required String habitName,
    required String elapsedTime,
  }) async {
    final seconds = _parseSecondsFromTime(elapsedTime);
    await startTimer(
      habitId: habitId, // FIX: Pass habitId
      habitName: habitName,
      elapsedSeconds: seconds,
    );
  }

  static Future<void> updateTimerNotification({
    required String habitName,
    required String elapsedTime,
  }) async {
    // This is no longer needed as the service updates itself.
  }

  static Future<void> cancelTimerNotification() async {
    await stopTimer();
  }

  static Future<void> cancelAll() async {
    await stopTimer();
  }

  /// Parse seconds from time string
  @pragma('vm:entry-point')
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

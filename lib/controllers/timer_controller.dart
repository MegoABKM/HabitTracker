import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart'; // FIX: Import background service
import 'package:get/get.dart';
import 'habit_controller.dart';
import '../models/habit_model.dart'; // FIX: Import HabitModel for safer lookup
import '../services/notification_service.dart';
import '../services/session_service.dart';

/// Controller for managing active timers
class TimerController extends GetxController {
  final HabitController _habitController = Get.find<HabitController>();

  // Currently running timer
  final currentHabitId = Rxn<int>();
  // FIX: The UI-thread timer is unreliable and stops in the background. It must be removed.
  // Timer? _timer;
  final elapsedSeconds = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // FIX: Listen for updates from the background service
    _configureBackgroundServiceListener();
  }

  /// FIX: Sets up a listener to receive time updates from the background service.
  void _configureBackgroundServiceListener() {
    FlutterBackgroundService().on('update').listen((event) {
      print('DEBUG: UI received update event: $event');
      final int? habitId = event?['habitId'];
      final int? seconds = event?['seconds'];

      print(
        'DEBUG: Parsed - habitId: $habitId, seconds: $seconds, currentHabitId: ${currentHabitId.value}',
      );

      // Only update if the event is for the currently tracked habit in the UI.
      if (habitId != null &&
          seconds != null &&
          currentHabitId.value == habitId) {
        elapsedSeconds.value = seconds;
        print('DEBUG: UI timer updated to: $seconds seconds');
      } else {
        print('DEBUG: Update ignored - habit mismatch or null values');
      }
    });
  }

  /// Start timer for a habit
  Future<void> startTimer(int habitId) async {
    // If timer is already running for this habit, do nothing
    if (isTimerRunningFor(habitId)) {
      return;
    }

    // Always stop any existing timer first
    if (isAnyTimerRunning) {
      await stopTimer(showMessage: false);
    }

    // Reset state
    currentHabitId.value = habitId;
    elapsedSeconds.value = 0;

    // FIX: Use a safer method to find the habit to prevent crashes.
    final habit = _findHabitById(habitId);
    if (habit == null) {
      Get.snackbar('Error', 'Habit not found. Cannot start timer.');
      // Clean up state if habit is not found
      currentHabitId.value = null;
      return;
    }

    // Persist session intent so we can recover after termination
    final startEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await SessionService.startSession(
      habitId: habit.id!,
      habitName: habit.name,
      startEpochSeconds: startEpoch,
    );

    // FIX: The UI-thread timer is removed. We now start the reliable background service.
    await NotificationService.startTimer(
      habitId: habit.id!,
      habitName: habit.name,
      elapsedSeconds: 0,
    );

    // The notification is now handled entirely by the background service.

    Get.snackbar(
      'Timer Started',
      'Tracking ${habit.name}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
    );
  }

  /// Stop the current timer and save time
  Future<void> stopTimer({bool showMessage = true}) async {
    final habitId = currentHabitId.value;
    // FIX: No UI timer to cancel anymore.
    // if (_timer != null) {
    //   _timer!.cancel();
    //   _timer = null;
    // }

    // Clear persisted session and stop service
    await SessionService.clearSession();
    // FIX: Tell the background service to stop.
    await NotificationService.stopTimer();

    if (habitId != null) {
      // Calculate minutes (round up to at least 1 minute)
      final minutes = elapsedSeconds.value ~/ 60;
      if (minutes > 0) {
        // Update habit time
        _habitController.updateHabitTime(habitId, minutes);
      } else if (elapsedSeconds.value > 0) {
        // If less than a minute, save as 1 minute
        _habitController.updateHabitTime(habitId, 1);
      }

      // Get habit name for snackbar
      final habit = _findHabitById(habitId);
      if (habit != null) {
        final savedMinutes =
            minutes > 0 ? minutes : (elapsedSeconds.value > 0 ? 1 : 0);

        if (showMessage) {
          Get.snackbar(
            'Timer Stopped',
            'Saved ${savedMinutes} minute(s) for ${habit.name}',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
            backgroundColor: Get.theme.colorScheme.secondaryContainer,
          );
        }
      }
    }

    currentHabitId.value = null;
    elapsedSeconds.value = 0;
  }

  /// Check if a specific habit timer is running
  bool isTimerRunningFor(int? habitId) {
    if (habitId == null) return false;
    // FIX: Logic now depends on the reactive currentHabitId
    return currentHabitId.value == habitId;
  }

  /// Check if any timer is running
  // FIX: Logic now depends on the reactive currentHabitId
  bool get isAnyTimerRunning => currentHabitId.value != null;

  /// Get formatted time string
  String getFormattedTime() {
    final totalSeconds = elapsedSeconds.value;
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

  /// Get elapsed time in seconds
  int getElapsedSeconds() => elapsedSeconds.value;

  // FIX: This method is no longer needed as state isn't persisted this way.
  // void _startTimerIfNeeded() { }

  @override
  void onClose() {
    // FIX: No UI timer to cancel. Notifications are managed by the service.
    // _timer?.cancel();
    NotificationService.cancelAll();
    super.onClose();
  }

  /// Resume from a saved session if present (used on app launch).
  Future<void> resumeFromSavedSession() async {
    final session = await SessionService.getActiveSession();
    if (session == null) return;

    currentHabitId.value = session.habitId;
    // Compute elapsed based on stored start epoch
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = (nowEpoch - session.startEpochSeconds).clamp(0, 1 << 30);
    elapsedSeconds.value = elapsed;

    await NotificationService.startTimer(
      habitId: session.habitId,
      habitName: session.habitName,
      elapsedSeconds: elapsed,
    );
  }

  /// FIX: This method is now redundant. The background service handles all notifications.
  // void _updateNotification() async { ... }

  /// FIX: Helper to safely find a habit by its ID.
  HabitModel? _findHabitById(int id) {
    try {
      return _habitController.habits.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }
}

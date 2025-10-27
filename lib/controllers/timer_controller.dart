import 'dart:async';
import 'package:get/get.dart';
import 'habit_controller.dart';
import '../services/notification_service.dart';

/// Controller for managing active timers
class TimerController extends GetxController {
  final HabitController _habitController = Get.find<HabitController>();

  // Currently running timer
  final currentHabitId = Rxn<int>();
  Timer? _timer;
  final elapsedSeconds = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Load any running timer state
    _startTimerIfNeeded();
  }

  /// Start timer for a habit
  Future<void> startTimer(int habitId) async {
    // If timer is already running for this habit, do nothing
    if (_timer != null && _timer!.isActive && currentHabitId.value == habitId) {
      return;
    }

    // Always stop any existing timer first
    if (_timer != null && _timer!.isActive) {
      await stopTimer(showMessage: false);
    }

    // Reset state
    currentHabitId.value = habitId;
    elapsedSeconds.value = 0;

    // Get habit info
    final habit = _habitController.habits.firstWhere(
      (h) => h.id == habitId,
      orElse: () => throw Exception('Habit not found'),
    );

    // Start local timer for UI updates
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds.value++;
      // Update notification every second
      _updateNotification();
    });

    // Start notification initially
    await NotificationService.showTimerNotification(
      habitName: habit.name,
      elapsedTime: getFormattedTime(),
    );

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
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }

    // Cancel notification
    await NotificationService.cancelTimerNotification();

    if (habitId != null) {
      // Calculate minutes (round up to at least 1 minute)
      final minutes = elapsedSeconds.value ~/ 60;
      if (minutes > 0) {
        // Update habit time
        _habitController.updateHabitTime(currentHabitId.value!, minutes);
      } else if (elapsedSeconds.value > 0) {
        // If less than a minute, save as 1 minute
        _habitController.updateHabitTime(currentHabitId.value!, 1);
      }

      // Get habit name for snackbar
      try {
        final habit = _habitController.habits.firstWhere(
          (h) => h.id == currentHabitId.value,
        );

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
      } catch (e) {
        // Habit not found
      }
    }

    currentHabitId.value = null;
    elapsedSeconds.value = 0;
  }

  /// Check if a specific habit timer is running
  bool isTimerRunningFor(int? habitId) {
    if (habitId == null) return false;
    return currentHabitId.value == habitId &&
        _timer != null &&
        _timer!.isActive;
  }

  /// Check if any timer is running
  bool get isAnyTimerRunning => _timer != null && _timer!.isActive;

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

  /// Resume timer if it was running
  void _startTimerIfNeeded() {
    // Timer starts fresh each app launch
  }

  @override
  void onClose() {
    _timer?.cancel();
    NotificationService.cancelAll();
    super.onClose();
  }

  /// Update notification with current time
  void _updateNotification() async {
    if (currentHabitId.value == null) return;

    try {
      final habit = _habitController.habits.firstWhere(
        (h) => h.id == currentHabitId.value,
      );

      await NotificationService.updateTimerNotification(
        habitName: habit.name,
        elapsedTime: getFormattedTime(),
      );
    } catch (e) {
      // Habit not found
    }
  }
}

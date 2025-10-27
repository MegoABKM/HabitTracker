import 'package:get/get.dart';
import '../models/habit_model.dart';
import '../services/database_service.dart';

/// Controller for managing habits and their state
class HabitController extends GetxController {
  final DatabaseService _databaseService = DatabaseService.instance;

  var habits = <HabitModel>[].obs;
  var isLoading = false.obs;
  var stats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadHabits();
    loadStats();
  }

  /// Load all habits from the database
  Future<void> loadHabits() async {
    try {
      isLoading.value = true;
      final loadedHabits = await _databaseService.getAllHabits();
      habits.value = loadedHabits;
    } catch (e) {
      print('Error loading habits: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a new habit
  Future<bool> addHabit({
    required String name,
    required String frequency,
    int? targetMinutes,
  }) async {
    try {
      final habit = HabitModel(
        name: name,
        frequency: frequency,
        targetMinutes: targetMinutes,
      );

      await _databaseService.addHabit(habit);
      await loadHabits();
      await loadStats();
      return true;
    } catch (e) {
      print('Error adding habit: $e');
      return false;
    }
  }

  /// Update an existing habit
  Future<bool> updateHabit(HabitModel habit) async {
    try {
      await _databaseService.updateHabit(habit);
      await loadHabits();
      await loadStats();
      return true;
    } catch (e) {
      print('Error updating habit: $e');
      return false;
    }
  }

  /// Delete a habit
  Future<bool> deleteHabit(int id) async {
    try {
      await _databaseService.deleteHabit(id);
      await loadHabits();
      await loadStats();
      return true;
    } catch (e) {
      print('Error deleting habit: $e');
      return false;
    }
  }

  /// Mark a habit as done for today
  Future<void> markHabitDone(int id) async {
    try {
      await _databaseService.markHabitDone(id);
      await loadHabits();
      await loadStats();

      // Show success feedback
      Get.snackbar(
        'Success',
        'Habit marked as completed!',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Get.theme.colorScheme.primaryContainer,
      );
    } catch (e) {
      print('Error marking habit done: $e');
      Get.snackbar(
        'Error',
        'Failed to mark habit as completed',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Get.theme.colorScheme.errorContainer,
      );
    }
  }

  /// Unmark a habit (undo today's completion)
  Future<void> unmarkHabitDone(int id) async {
    try {
      await _databaseService.unmarkHabitDone(id);
      await loadHabits();
      await loadStats();
    } catch (e) {
      print('Error unmarking habit done: $e');
    }
  }

  /// Load statistics for analytics page
  Future<void> loadStats() async {
    try {
      final loadedStats = await _databaseService.getCompletionStats();
      stats.value = loadedStats;
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  /// Calculate progress percentage for a habit
  double calculateProgress(HabitModel habit) {
    // Simple progress calculation based on streak
    if (habit.streak == 0) return 0.0;
    return (habit.streak / 100.0).clamp(0.0, 1.0); // Cap at 1.0 (100%)
  }

  /// Get today's completion count
  int getTodayCompletionCount() {
    return habits.where((habit) => habit.isCompletedToday).length;
  }

  /// Update time spent on a habit
  Future<void> updateHabitTime(int id, int minutes) async {
    try {
      await _databaseService.updateTimeSpent(id, minutes);
      await loadHabits();
    } catch (e) {
      print('Error updating habit time: $e');
      Get.snackbar(
        'Error',
        'Failed to update time',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Set time spent manually
  Future<void> setHabitTime(int id, int minutes) async {
    try {
      await _databaseService.setTimeSpent(id, minutes);
      await loadHabits();
    } catch (e) {
      print('Error setting habit time: $e');
      Get.snackbar(
        'Error',
        'Failed to set time',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Get today's total time across all habits
  Future<int> getTodayTotalTime() async {
    try {
      return await _databaseService.getTodayTotalTime();
    } catch (e) {
      print('Error getting today total time: $e');
      return 0;
    }
  }

  /// Get all-time total time across all habits
  Future<int> getTotalTimeSpent() async {
    try {
      return await _databaseService.getTotalTimeSpent();
    } catch (e) {
      print('Error getting total time: $e');
      return 0;
    }
  }

  /// Load time chart data for analytics
  Future<Map<String, dynamic>> loadTimeChartData() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: 7));

      final history = await _databaseService.getTimeChartData(weekStart, now);

      // Group by habit name
      final Map<String, int> habitTimeMap = {};
      for (var entry in history) {
        final habitName = entry['habit_name'] as String;
        final time = entry['total_time'] as int? ?? 0;
        habitTimeMap[habitName] = (habitTimeMap[habitName] ?? 0) + time;
      }

      return {'history': history, 'habitTimeMap': habitTimeMap};
    } catch (e) {
      print('Error loading time chart data: $e');
      return {'history': [], 'habitTimeMap': {}};
    }
  }
}

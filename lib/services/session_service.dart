import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistence for an active timer session.
class SessionService {
  static const String _keyActive = 'active_session';
  static const String _keyHabitId = 'active_habit_id';
  static const String _keyHabitName = 'active_habit_name';
  static const String _keyStartEpoch = 'active_start_epoch_secs';

  /// Start an active session for a habit at [startEpochSeconds].
  static Future<void> startSession({
    required int habitId,
    required String habitName,
    required int startEpochSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyActive, true);
    await prefs.setInt(_keyHabitId, habitId);
    await prefs.setString(_keyHabitName, habitName);
    await prefs.setInt(_keyStartEpoch, startEpochSeconds);
  }

  /// Clear any active session.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActive);
    await prefs.remove(_keyHabitId);
    await prefs.remove(_keyHabitName);
    await prefs.remove(_keyStartEpoch);
  }

  /// Returns null if no active session is stored.
  static Future<ActiveSession?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_keyActive) ?? false;
    if (!isActive) return null;
    final habitId = prefs.getInt(_keyHabitId);
    final habitName = prefs.getString(_keyHabitName);
    final startEpoch = prefs.getInt(_keyStartEpoch);
    if (habitId == null || habitName == null || startEpoch == null) return null;
    return ActiveSession(
      habitId: habitId,
      habitName: habitName,
      startEpochSeconds: startEpoch,
    );
  }
}

class ActiveSession {
  final int habitId;
  final String habitName;
  final int startEpochSeconds;

  const ActiveSession({
    required this.habitId,
    required this.habitName,
    required this.startEpochSeconds,
  });
}

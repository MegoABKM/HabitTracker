import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit_model.dart';

/// Service class for managing database operations
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  /// Initialize database and create tables
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handle database migration from version 1 to version 2
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for time tracking
      await db.execute('''
        ALTER TABLE habits ADD COLUMN timeSpentToday INTEGER DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE habits ADD COLUMN totalTimeSpent INTEGER DEFAULT 0
      ''');
    }
    if (oldVersion < 3) {
      // Create completion_history table
      await db.execute('''
        CREATE TABLE completion_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          habit_id INTEGER NOT NULL,
          completion_date TEXT NOT NULL,
          time_spent INTEGER DEFAULT 0,
          FOREIGN KEY (habit_id) REFERENCES habits (id)
        )
      ''');
    }
  }

  /// Create habits table
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        frequency TEXT NOT NULL,
        streak INTEGER DEFAULT 0,
        lastCompleted TEXT,
        targetMinutes INTEGER,
        progress REAL DEFAULT 0.0,
        isCompletedToday INTEGER DEFAULT 0,
        timeSpentToday INTEGER DEFAULT 0,
        totalTimeSpent INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE completion_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        completion_date TEXT NOT NULL,
        time_spent INTEGER DEFAULT 0,
        FOREIGN KEY (habit_id) REFERENCES habits (id)
      )
    ''');
  }

  /// Add a new habit to the database
  Future<int> addHabit(HabitModel habit) async {
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  /// Update an existing habit
  Future<int> updateHabit(HabitModel habit) async {
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Delete a habit from the database
  Future<int> deleteHabit(int id) async {
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  /// Save completion history
  Future<void> _saveCompletionHistory(
    int habitId,
    String date,
    int timeSpent,
  ) async {
    final db = await database;
    // Check if record exists for this date
    final existing = await db.query(
      'completion_history',
      where: 'habit_id = ? AND completion_date = ?',
      whereArgs: [habitId, date],
    );

    if (existing.isEmpty) {
      await db.insert('completion_history', {
        'habit_id': habitId,
        'completion_date': date,
        'time_spent': timeSpent,
      });
    } else {
      await db.update(
        'completion_history',
        {'time_spent': timeSpent},
        where: 'habit_id = ? AND completion_date = ?',
        whereArgs: [habitId, date],
      );
    }
  }

  /// Mark a habit as done for today
  Future<int> markHabitDone(int id) async {
    final db = await database;
    final now = DateTime.now();
    final nowStr = now.toIso8601String();
    final todayStr = DateTime(now.year, now.month, now.day).toIso8601String();

    // Check if last completed was yesterday or earlier
    final habit = await getHabitById(id);
    if (habit != null) {
      bool shouldIncrementStreak = true;

      if (habit.lastCompleted != null) {
        final lastDate = DateTime.parse(habit.lastCompleted!);
        final today = DateTime.now();
        final difference = today.difference(lastDate).inDays;

        // If completed today already, don't increment
        if (difference == 0) {
          shouldIncrementStreak = false;
        } else if (difference > 1) {
          // If gap is more than 1 day, reset streak
          await db.update(
            'habits',
            {'streak': 1, 'lastCompleted': nowStr, 'isCompletedToday': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
          await _saveCompletionHistory(id, todayStr, habit.timeSpentToday);
          return 1;
        }
      }

      final newStreak = shouldIncrementStreak ? habit.streak + 1 : habit.streak;

      final result = await db.update(
        'habits',
        {'streak': newStreak, 'lastCompleted': nowStr, 'isCompletedToday': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      // Save completion history with today's time
      await _saveCompletionHistory(id, todayStr, habit.timeSpentToday);

      return result;
    }
    return 0;
  }

  /// Unmark a habit (undo today's completion)
  Future<int> unmarkHabitDone(int id) async {
    final db = await database;
    final habit = await getHabitById(id);

    if (habit != null && habit.lastCompleted != null) {
      final lastDate = DateTime.parse(habit.lastCompleted!);
      final today = DateTime.now();

      // Only unmark if it was completed today
      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        final newStreak = (habit.streak > 0) ? habit.streak - 1 : 0;

        return await db.update(
          'habits',
          {'isCompletedToday': 0, 'streak': newStreak},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
    return 0;
  }

  /// Get a single habit by ID
  Future<HabitModel?> getHabitById(int id) async {
    final db = await database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return HabitModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  /// Get all habits from the database
  Future<List<HabitModel>> getAllHabits() async {
    final db = await database;
    final result = await db.query('habits', orderBy: 'id DESC');

    // Reset isCompletedToday status for habits not completed today
    final now = DateTime.now();

    for (var habit in result) {
      if (habit['lastCompleted'] != null) {
        final lastDate = DateTime.parse(habit['lastCompleted'] as String);
        if (lastDate.year != now.year ||
            lastDate.month != now.month ||
            lastDate.day != now.day) {
          await db.update(
            'habits',
            {'isCompletedToday': 0},
            where: 'id = ?',
            whereArgs: [habit['id']],
          );
        }
      }
    }

    // Re-fetch all habits after reset
    final updatedResult = await db.query('habits', orderBy: 'id DESC');
    return updatedResult.map((map) => HabitModel.fromMap(map)).toList();
  }

  /// Get completion statistics for analytics
  Future<Map<String, dynamic>> getCompletionStats() async {
    final habits = await getAllHabits();

    if (habits.isEmpty) {
      return {
        'totalHabits': 0,
        'completedToday': 0,
        'averageProgress': 0.0,
        'averageStreak': 0.0,
        'weeklyData': <Map<String, dynamic>>[],
        'streakTrends': <Map<String, dynamic>>[],
      };
    }

    final completedToday = habits.where((h) => h.isCompletedToday).length;
    final averageProgress =
        habits.fold<double>(0.0, (sum, h) => sum + h.progress) / habits.length;
    final averageStreak =
        habits.fold<double>(0.0, (sum, h) => sum + h.streak) / habits.length;

    // Generate weekly data (last 7 days)
    final weeklyData = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      return {
        'date': date,
        'day': _getDayName(date.weekday),
        'completed':
            habits
                .length, // Placeholder - you can enhance this with actual completion data per day
      };
    });

    // Generate streak trends (last 7 days of streak data)
    final streakTrends =
        habits
            .map((habit) => {'name': habit.name, 'streak': habit.streak})
            .toList();

    return {
      'totalHabits': habits.length,
      'completedToday': completedToday,
      'averageProgress': averageProgress,
      'averageStreak': averageStreak,
      'weeklyData': weeklyData,
      'streakTrends': streakTrends,
    };
  }

  /// Clear all habits from the database
  Future<int> clearAllHabits() async {
    final db = await database;
    return await db.delete('habits');
  }

  /// Helper method to get day name
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Update time spent on a habit today
  Future<int> updateTimeSpent(int id, int minutes) async {
    final db = await database;
    final habit = await getHabitById(id);

    if (habit != null) {
      final newTimeSpentToday = habit.timeSpentToday + minutes;
      final newTotalTimeSpent = habit.totalTimeSpent + minutes;

      return await db.update(
        'habits',
        {
          'timeSpentToday': newTimeSpentToday,
          'totalTimeSpent': newTotalTimeSpent,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  /// Set time spent manually
  Future<int> setTimeSpent(int id, int minutes) async {
    final db = await database;
    final habit = await getHabitById(id);

    if (habit != null) {
      final timeDifference = minutes - habit.timeSpentToday;

      return await db.update(
        'habits',
        {
          'timeSpentToday': minutes,
          'totalTimeSpent': habit.totalTimeSpent + timeDifference,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    return 0;
  }

  /// Reset daily time at midnight
  Future<void> resetDailyTime() async {
    final db = await database;
    await db.update('habits', {'timeSpentToday': 0});
  }

  /// Get total time spent across all habits
  Future<int> getTotalTimeSpent() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(totalTimeSpent) as total FROM habits',
    );
    return result.first['total'] as int? ?? 0;
  }

  /// Get today's total time across all habits
  Future<int> getTodayTotalTime() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(timeSpentToday) as total FROM habits',
    );
    return result.first['total'] as int? ?? 0;
  }

  /// Get completion history for a specific date range
  Future<List<Map<String, dynamic>>> getCompletionHistory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    return await db.rawQuery(
      '''
      SELECT 
        ch.completion_date,
        ch.time_spent,
        h.name as habit_name,
        h.id as habit_id
      FROM completion_history ch
      JOIN habits h ON ch.habit_id = h.id
      WHERE ch.completion_date >= ? AND ch.completion_date <= ?
      ORDER BY ch.completion_date DESC
    ''',
      [startStr, endStr],
    );
  }

  /// Get daily completion data for calendar
  Future<Map<String, List<Map<String, dynamic>>>> getDailyCompletionData(
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final history = await getCompletionHistory(startDate, endDate);

    // Group by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in history) {
      final date = entry['completion_date'] as String;
      final dateOnly = date.split('T')[0]; // Get YYYY-MM-DD

      if (!grouped.containsKey(dateOnly)) {
        grouped[dateOnly] = [];
      }
      grouped[dateOnly]!.add({
        'habit_name': entry['habit_name'],
        'habit_id': entry['habit_id'],
        'time_spent': entry['time_spent'],
      });
    }

    return grouped;
  }

  /// Get time spent on each habit for a date range
  Future<List<Map<String, dynamic>>> getTimeChartData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        ch.completion_date,
        h.name as habit_name,
        SUM(ch.time_spent) as total_time
      FROM completion_history ch
      JOIN habits h ON ch.habit_id = h.id
      WHERE ch.completion_date >= ? AND ch.completion_date <= ?
      GROUP BY ch.completion_date, h.id
      ORDER BY ch.completion_date ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

/// Model class representing a habit
class HabitModel {
  final int? id;
  final String name;
  final String frequency;
  final int streak;
  final String? lastCompleted;
  final int? targetMinutes;
  final double progress;
  final bool isCompletedToday;
  final int timeSpentToday; // Time spent in minutes today
  final int totalTimeSpent; // Total time spent in minutes

  HabitModel({
    this.id,
    required this.name,
    required this.frequency,
    this.streak = 0,
    this.lastCompleted,
    this.targetMinutes,
    this.progress = 0.0,
    this.isCompletedToday = false,
    this.timeSpentToday = 0,
    this.totalTimeSpent = 0,
  });

  /// Create HabitModel from database map
  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map['id'],
      name: map['name'],
      frequency: map['frequency'],
      streak: map['streak'] ?? 0,
      lastCompleted: map['lastCompleted'],
      targetMinutes: map['targetMinutes'],
      progress: map['progress']?.toDouble() ?? 0.0,
      isCompletedToday: map['isCompletedToday'] == 1,
      timeSpentToday: map['timeSpentToday'] ?? 0,
      totalTimeSpent: map['totalTimeSpent'] ?? 0,
    );
  }

  /// Convert HabitModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'frequency': frequency,
      'streak': streak,
      'lastCompleted': lastCompleted,
      'targetMinutes': targetMinutes,
      'progress': progress,
      'isCompletedToday': isCompletedToday ? 1 : 0,
      'timeSpentToday': timeSpentToday,
      'totalTimeSpent': totalTimeSpent,
    };
  }

  /// Create a copy of the model with updated fields
  HabitModel copyWith({
    int? id,
    String? name,
    String? frequency,
    int? streak,
    String? lastCompleted,
    int? targetMinutes,
    double? progress,
    bool? isCompletedToday,
    int? timeSpentToday,
    int? totalTimeSpent,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      progress: progress ?? this.progress,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      timeSpentToday: timeSpentToday ?? this.timeSpentToday,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../models/habit_model.dart';
import '../controllers/habit_controller.dart';
import '../controllers/timer_controller.dart';
import '../utils/translation_helper.dart';

/// Widget for displaying a habit card with progress and streak
class HabitCard extends StatelessWidget {
  final HabitModel habit;
  final HabitController controller;

  const HabitCard({super.key, required this.habit, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerController = Get.find<TimerController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.toNamed('/add-habit', arguments: habit);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    habit.isCompletedToday
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Completion Checkbox
                    GestureDetector(
                      onTap: () {
                        if (habit.isCompletedToday) {
                          controller.unmarkHabitDone(habit.id!);
                        } else {
                          controller.markHabitDone(habit.id!);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient:
                              habit.isCompletedToday
                                  ? LinearGradient(
                                    colors: [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF9F7AFF),
                                    ],
                                  )
                                  : null,
                          color:
                              habit.isCompletedToday
                                  ? null
                                  : Colors.transparent,
                          border: Border.all(
                            color:
                                habit.isCompletedToday
                                    ? Colors.transparent
                                    : theme.colorScheme.outline.withOpacity(
                                      0.3,
                                    ),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow:
                              habit.isCompletedToday
                                  ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6C63FF,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : null,
                        ),
                        child:
                            habit.isCompletedToday
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 28,
                                )
                                : Icon(
                                  Icons.circle_outlined,
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.3,
                                  ),
                                  size: 28,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Streak and Frequency Info - Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildInfoChip(
                        theme,
                        Icons.local_fire_department,
                        '${habit.streak} day',
                        Colors.orange,
                      ),
                      SizedBox(width: 8.w),
                      _buildInfoChip(
                        theme,
                        Icons.schedule,
                        habit.frequency,
                        Colors.blue,
                      ),
                      if (habit.targetMinutes != null) ...[
                        SizedBox(width: 8.w),
                        _buildInfoChip(
                          theme,
                          Icons.timer,
                          '${habit.targetMinutes}min',
                          Colors.purple,
                        ),
                      ],
                      if (habit.timeSpentToday > 0) ...[
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => _showTimeDialog(theme, habit),
                          child: _buildInfoChip(
                            theme,
                            Icons.access_time,
                            '${habit.timeSpentToday}min',
                            Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Timer Section
                Obx(() {
                  final isRunning =
                      timerController.currentHabitId.value == habit.id;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isRunning
                              ? const Color(0xFF6C63FF).withOpacity(0.1)
                              : theme.colorScheme.surfaceVariant.withOpacity(
                                0.3,
                              ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isRunning
                                ? const Color(0xFF6C63FF).withOpacity(0.3)
                                : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRunning ? 'timerRunning'.tr : 'quickTimer'.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isRunning) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timerController.getFormattedTime(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (isRunning) {
                              await timerController.stopTimer();
                            } else {
                              await timerController.startTimer(habit.id!);
                            }
                          },
                          icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                          label: Text(isRunning ? 'stop'.tr : 'start'.tr),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isRunning
                                    ? Colors.red
                                    : const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (habit.targetMinutes != null ||
                    habit.timeSpentToday > 0) ...[
                  const SizedBox(height: 12),
                  // Time Tracking Section (realtime with running timer)
                  Obx(() {
                    final isRunning =
                        timerController.currentHabitId.value == habit.id;
                    final liveElapsedSeconds =
                        isRunning ? timerController.getElapsedSeconds() : 0;
                    final liveExtraMinutes = liveElapsedSeconds ~/ 60;
                    final todayMinutes =
                        habit.timeSpentToday + liveExtraMinutes;
                    final target = habit.targetMinutes ?? 0;
                    final percent =
                        target > 0
                            ? (todayMinutes / target).clamp(0.0, 1.0)
                            : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'timeSpentToday'.tr,
                              style: theme.textTheme.bodySmall,
                            ),
                            if (habit.timeSpentToday == 0)
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () => _showTimeDialog(theme, habit),
                                tooltip: 'addTime'.tr,
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.tertiary,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${'minUnit'.trWithParams({'minutes': '$todayMinutes'})} / ${'minUnit'.trWithParams({'minutes': '${habit.targetMinutes ?? 0}'})}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],

                const SizedBox(height: 12),

                // Progress Bar (derive from target minutes for consistency)
                Obx(() {
                  final isRunning =
                      timerController.currentHabitId.value == habit.id;
                  final liveElapsedSeconds =
                      isRunning ? timerController.getElapsedSeconds() : 0;
                  final liveExtraMinutes = liveElapsedSeconds ~/ 60;
                  final target = habit.targetMinutes ?? 0;
                  final todayMinutes = habit.timeSpentToday + liveExtraMinutes;
                  final progress =
                      target > 0
                          ? (todayMinutes / target).clamp(0.0, 1.0)
                          : 0.0;
                  final percentText = (progress * 100).toInt();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('progress'.tr, style: theme.textTheme.bodySmall),
                          Text(
                            '$percentText%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeDialog(ThemeData theme, HabitModel habit) {
    final timeController = TextEditingController(
      text: habit.timeSpentToday.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: Text('Time Spent - ${habit.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today: ${habit.timeSpentToday} minutes',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${habit.totalTimeSpent} minutes',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Set Time (minutes)',
                border: OutlineInputBorder(),
                helperText: 'Enter time spent today',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(timeController.text) ?? 0;
              if (minutes >= 0) {
                controller.setHabitTime(habit.id!, minutes);
                Get.back();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

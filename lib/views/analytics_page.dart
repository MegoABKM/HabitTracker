import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/habit_controller.dart';
import '../widgets/progress_chart.dart';
import '../utils/translation_helper.dart';

/// Analytics page showing charts and statistics
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  var timeChartData = <String, dynamic>{}.obs;
  bool isLoadingTimeData = false;

  @override
  void initState() {
    super.initState();
    loadTimeData();
  }

  Future<void> loadTimeData() async {
    setState(() => isLoadingTimeData = true);
    final controller = Get.find<HabitController>();
    final data = await controller.loadTimeChartData();
    setState(() {
      timeChartData.value = data;
      isLoadingTimeData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<HabitController>();

    return Scaffold(
      appBar: AppBar(title: Text('analytics'.tr)),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async {
            await controller.loadStats();
            await controller.loadHabits();
          },
          child: ListView(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF6E56CF), // Brand Primary Violet
                      Color(0xFF8B6EFF), // Lighter Violet
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.insights,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'yourProgressOverview'.tr,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'trackConsistency'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Charts
              ProgressChart(controller: controller),

              const SizedBox(height: 24),

              // Time Chart by Habit
              if (!isLoadingTimeData && timeChartData['habitTimeMap'] != null)
                _buildTimeByHabitChart(theme),

              const SizedBox(height: 24),

              // Top Habits Section
              if (controller.habits.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Top Performing Habits',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ...() {
                  final habitsWithStreak =
                      controller.habits.where((h) => h.streak > 0).toList();
                  habitsWithStreak.sort((a, b) => b.streak.compareTo(a.streak));
                  return habitsWithStreak
                      .take(3)
                      .map((habit) => _buildTopHabitCard(theme, habit))
                      .toList();
                }(),
              ],

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTimeByHabitChart(ThemeData theme) {
    final habitTimeMap = timeChartData['habitTimeMap'] as Map<String, int>;

    if (habitTimeMap.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEntries =
        habitTimeMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final maxTime = sortedEntries.isNotEmpty ? sortedEntries.first.value : 1;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'timeByHabitLast7'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: (sortedEntries.length * 50.0).clamp(200.0, 400.0),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: true),
                maxY: maxTime.toDouble(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}m',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedEntries.length) {
                          final entry = sortedEntries[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entry.key.length > 10
                                  ? '${entry.key.substring(0, 10)}...'
                                  : entry.key,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barGroups:
                    sortedEntries.asMap().entries.map((entry) {
                      final index = entry.key;
                      final habitEntry = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: habitEntry.value.toDouble(),
                            color: theme.colorScheme.tertiary,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend showing actual times
          ...sortedEntries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      entry.key,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'minUnit'.trWithParams({'minutes': '${entry.value}'}),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopHabitCard(ThemeData theme, habit) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_fire_department, color: Colors.orange),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${habit.frequency} habit'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${habit.streak}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text('daysLabel'.tr, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

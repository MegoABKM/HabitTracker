import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import '../controllers/habit_controller.dart';
import '../services/database_service.dart';

/// Calendar page showing daily habits with time
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final controller = Get.find<HabitController>();
  final selectedDay = ValueNotifier(DateTime.now());
  DateTime focusedDay = DateTime.now();
  Map<String, List<Map<String, dynamic>>> dailyData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    setState(() => isLoading = true);
    final monthData = await DatabaseService.instance.getDailyCompletionData(
      focusedDay,
    );
    setState(() {
      dailyData = monthData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: focusedDay,
                    selectedDayPredicate:
                        (day) => isSameDay(selectedDay.value, day),
                    onDaySelected: (selected, focused) {
                      selectedDay.value = selected;
                    },
                    onPageChanged: (focused) {
                      setState(() => focusedDay = focused);
                      loadCalendarData();
                    },
                    eventLoader: (day) {
                      final dateStr =
                          DateTime(
                            day.year,
                            day.month,
                            day.day,
                          ).toIso8601String().split('T')[0];
                      return dailyData[dateStr] ?? [];
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ValueListenableBuilder<DateTime>(
                      valueListenable: selectedDay,
                      builder: (context, selected, child) {
                        return _buildSelectedDayView(theme, selected);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSelectedDayView(ThemeData theme, DateTime selected) {
    final dateStr =
        DateTime(
          selected.year,
          selected.month,
          selected.day,
        ).toIso8601String().split('T')[0];
    final habits = dailyData[dateStr] ?? [];

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits completed',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    final totalTime = habits.fold<int>(
      0,
      (sum, h) => sum + (h['time_spent'] as int? ?? 0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(selected),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Total: $totalTime minutes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...habits.map((habit) => _buildHabitCard(theme, habit)),
        ],
      ),
    );
  }

  Widget _buildHabitCard(ThemeData theme, Map<String, dynamic> habit) {
    final timeSpent = habit['time_spent'] as int? ?? 0;
    final habitName = habit['habit_name'] as String? ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.check_circle, color: theme.colorScheme.primary),
        ),
        title: Text(
          habitName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Completed habit'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$timeSpent min',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

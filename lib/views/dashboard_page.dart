import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/habit_controller.dart';
import '../controllers/timer_controller.dart';
import '../widgets/habit_card.dart';
import '../utils/translation_helper.dart';

/// Dashboard page showing all habits
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final int _quoteIndex;

  @override
  void initState() {
    super.initState();
    _quoteIndex = DateTime.now().millisecondsSinceEpoch % 20 + 1;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HabitController>();
    final timerController = Get.find<TimerController>();
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: Obx(() {
        final currentId = timerController.currentHabitId.value;

        if (currentId == null) {
          return const SizedBox.shrink();
        }

        try {
          final habit = controller.habits.firstWhere((h) => h.id == currentId);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF6C63FF), const Color(0xFF9F7AFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        // Listen to elapsedSeconds changes
                        Obx(() {
                          return Text(
                            timerController.getFormattedTime(),
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await timerController.stopTimer();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6C63FF),
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          return const SizedBox.shrink();
        }
      }),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'appTitle'.tr,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
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
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => Get.toNamed('/calendar'),
                tooltip: 'calendar'.tr,
              ),
              IconButton(
                icon: const Icon(Icons.analytics_outlined),
                onPressed: () => Get.toNamed('/analytics'),
                tooltip: 'analytics'.tr,
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Get.toNamed('/settings'),
                tooltip: 'settings'.tr,
              ),
            ],
          ),

          // Motivational Quote
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.1),
                    const Color(0xFF9F7AFF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFF6C63FF),
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      _localizedQuote(_quoteIndex),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Today's Progress Summary
          SliverToBoxAdapter(
            child: Obx(() {
              final total = controller.habits.length;
              final completed = controller.getTodayCompletionCount();
              final totalTimeToday = controller.habits.fold<int>(
                0,
                (sum, habit) => sum + habit.timeSpentToday,
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [Color(0xFF6C63FF), Color(0xFF9F7AFF)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.track_changes,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'todaysProgress'.tr,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    Text(
                                      'ofCount'.trWithParams({
                                        'completed': '$completed',
                                        'total': '$total',
                                      }),
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: LinearProgressIndicator(
                              value: total > 0 ? completed / total : 0.0,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 10.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            Icons.access_time,
                            '$totalTimeToday min',
                            'today'.tr,
                            const Color(0xFFFF6B9D),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildStatCard(
                            theme,
                            Icons.timeline,
                            '${controller.habits.fold<int>(0, (sum, h) => sum + h.totalTimeSpent)} min',
                            'total'.tr,
                            const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Habits List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'appTitle'.tr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Habits List
          Obx(() {
            if (controller.isLoading.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (controller.habits.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No habits yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first habit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final habit = controller.habits[index];
                return HabitCard(habit: habit, controller: controller);
              }, childCount: controller.habits.length),
            );
          }),

          // Spacer to avoid FAB overlapping content
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-habit'),
        icon: const Icon(Icons.add),
        label: Text('newHabit'.tr),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _localizedQuote(int index) {
    switch (index) {
      case 1:
        return 'quote_1'.tr;
      case 2:
        return 'quote_2'.tr;
      case 3:
        return 'quote_3'.tr;
      case 4:
        return 'quote_4'.tr;
      case 5:
        return 'quote_5'.tr;
      case 6:
        return 'quote_6'.tr;
      case 7:
        return 'quote_7'.tr;
      case 8:
        return 'quote_8'.tr;
      case 9:
        return 'quote_9'.tr;
      case 10:
        return 'quote_10'.tr;
      case 11:
        return 'quote_11'.tr;
      case 12:
        return 'quote_12'.tr;
      case 13:
        return 'quote_13'.tr;
      case 14:
        return 'quote_14'.tr;
      case 15:
        return 'quote_15'.tr;
      case 16:
        return 'quote_16'.tr;
      case 17:
        return 'quote_17'.tr;
      case 18:
        return 'quote_18'.tr;
      case 19:
        return 'quote_19'.tr;
      default:
        return 'quote_20'.tr;
    }
  }
}

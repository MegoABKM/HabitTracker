import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/habit_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/database_service.dart';
import '../utils/permission_handler.dart';

/// Settings page for app configuration
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitController = Get.find<HabitController>();
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Permissions Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.1),
                  const Color(0xFF9F7AFF).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Color(0xFF6C63FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background Permissions',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Required for time tracking',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await PermissionHandler.requestOverlayPermission();
                    await PermissionHandler.requestIgnoreBatteryOptimization();
                    Get.snackbar(
                      'Permissions',
                      'Check system settings if needed',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Grant All Permissions'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),

          // Theme Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile(
                    value: themeController.isDarkMode.value,
                    onChanged: (value) => themeController.toggleTheme(),
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      themeController.isDarkMode.value ? 'Dark' : 'Light',
                    ),
                    secondary: Icon(
                      themeController.isDarkMode.value
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Data Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Management',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Clear All Data Button
                ListTile(
                  leading: Icon(
                    Icons.delete_sweep,
                    color: theme.colorScheme.error,
                  ),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all habits and history'),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onTap: () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Clear All Data'),
                        content: const Text(
                          'Are you sure you want to delete all habits and their history? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Delete All'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await DatabaseService.instance.clearAllHabits();
                      await habitController.loadHabits();
                      Get.back();
                      Get.snackbar(
                        'Deleted',
                        'All habits have been cleared',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Description'),
                  subtitle: const Text(
                    'Track your habits and build consistency',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

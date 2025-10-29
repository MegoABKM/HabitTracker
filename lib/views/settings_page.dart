import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final currentLocale = Get.locale ?? Get.deviceLocale ?? const Locale('en');
    final supported = const [
      Locale('en'),
      Locale('es'),
      Locale('fr'),
      Locale('de'),
      Locale('ar'),
      Locale('pt'),
      Locale('hi'),
      Locale('tr'),
      Locale('id'),
      Locale('ru'),
      Locale('zh'),
      Locale('ja'),
      Locale('ko'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('settingsTitle'.tr)),
      body: ListView(
        children: [
          // Language Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'language'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Locale>(
                  value: supported.firstWhere(
                    (l) => l.languageCode == currentLocale.languageCode,
                    orElse: () => const Locale('en'),
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items:
                      supported
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(_localeLabel(l)),
                            ),
                          )
                          .toList(),
                  onChanged: (l) async {
                    if (l == null) return;
                    Get.updateLocale(l);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('app_locale', l.languageCode);
                    } catch (_) {}
                    Get.snackbar(
                      'language'.tr,
                      '${'changedTo'.tr} ${_localeLabel(l)}',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                ),
              ],
            ),
          ),
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
                            'backgroundPermissions'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'requiredForTimeTracking'.tr,
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
                      'backgroundPermissions'.tr,
                      'requiredForTimeTracking'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text('grantAllPermissions'.tr),
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
                  'appearance'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile(
                    value: themeController.isDarkMode.value,
                    onChanged: (value) => themeController.toggleTheme(),
                    title: Text('darkMode'.tr),
                    subtitle: Text(
                      themeController.isDarkMode.value ? 'dark'.tr : 'light'.tr,
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
                  'dataManagement'.tr,
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
                  title: Text('clearAllData'.tr),
                  subtitle: Text('deleteAll'.tr),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onTap: () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: Text('clearAllData'.tr),
                        content: Text('areYouSureDeleteAll'.tr),
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
                            child: Text('deleteAll'.tr),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await DatabaseService.instance.clearAllHabits();
                      await habitController.loadHabits();
                      Get.back();
                      Get.snackbar(
                        'deleted'.tr,
                        'allHabitsCleared'.tr,
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
                  'about'.tr,
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
                  title: Text('version'.tr),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text('description'.tr),
                  subtitle: Text('trackConsistency'.tr),
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

String _localeLabel(Locale l) {
  switch (l.languageCode) {
    case 'en':
      return 'English';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    case 'de':
      return 'Deutsch';
    case 'ar':
      return 'العربية';
    case 'pt':
      return 'Português';
    case 'hi':
      return 'हिन्दी';
    case 'tr':
      return 'Türkçe';
    case 'id':
      return 'Bahasa Indonesia';
    case 'ru':
      return 'Русский';
    case 'zh':
      return '中文';
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    default:
      return l.languageCode;
  }
}

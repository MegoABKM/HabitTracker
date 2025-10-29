import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'controllers/habit_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/timer_controller.dart';
import 'services/notification_service.dart';
import 'views/dashboard_page.dart';
import 'views/add_habit_page.dart';
import 'views/analytics_page.dart';
import 'views/settings_page.dart';
import 'views/calendar_page.dart';
import 'utils/permission_handler.dart';
import 'utils/json_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final Translations appTranslations;
Locale? _savedLocale;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service first
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Failed to initialize notification service: $e');
  }

  // Initialize controllers
  Get.put(ThemeController());
  Get.put(HabitController());
  final timerController = Get.put(TimerController());
  // Load JSON translation overrides (e.g., placeholder order per locale)
  try {
    await JsonTranslations.loadLocales([
      'en',
      'ar',
      'es',
      'fr',
      'de',
      'pt',
      'hi',
      'tr',
      'id',
      'ru',
      'zh',
      'ja',
      'ko',
    ]);
  } catch (e) {
    // ignore
  }

  // Use JSON-only translations; ensure at least 'en' exists in assets
  appTranslations = JsonTranslations(JsonTranslations.loadedKeys());

  // Load saved locale preference
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale');
    if (code != null && code.isNotEmpty) {
      _savedLocale = Locale(code);
    }
  } catch (e) {
    // ignore
  }

  // Attempt to resume any active timer session before showing UI
  try {
    await timerController.resumeFromSavedSession();
  } catch (e) {
    // Non-fatal: just log
    // ignore: avoid_print
    print('Resume session failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Prompt for required permissions to ensure background timer reliability
    // Runs after first frame to ensure Navigator is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHandler.requestAllPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Habit Tracker Time',
        debugShowCheckedModeBanner: false,
        translations: appTranslations,
        locale: _savedLocale ?? Get.deviceLocale,
        fallbackLocale: const Locale('en'),

        // Responsive Design
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: ScreenUtilInit(
              designSize: const Size(360, 800),
              minTextAdapt: true,
              splitScreenMode: false,
              child: child,
            ),
          );
        },

        // Theme Configuration
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: themeController.themeMode,

        // Initial Route
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const DashboardPage()),
          GetPage(name: '/add-habit', page: () => const AddHabitPage()),
          GetPage(name: '/analytics', page: () => const AnalyticsPage()),
          GetPage(name: '/calendar', page: () => const CalendarPage()),
          GetPage(name: '/settings', page: () => const SettingsPage()),
        ],
      ),
    );
  }

  /// Build light theme
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6E56CF), // Brand Primary Violet
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.cairoTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        highlightElevation: 12,
        backgroundColor: const Color(0xFF22C3A6), // Brand Teal Accent
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B80FF),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E1E1E),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B80FF), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

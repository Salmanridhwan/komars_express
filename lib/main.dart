import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/pref_keys.dart';
import 'core/database/database_helper.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/notification_helper.dart';
import 'features/home/screens/settings_screen.dart';

void main() async {
  // Ensure widget bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database connection
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Triggers open & configure DDL

  // Initialize system notifications helper
  await NotificationHelper.instance.init();

  // Load user theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(PrefKeys.isDarkMode) ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          title: 'Komars App',
          debugShowCheckedModeBanner: false,
          
          // Theme configurations
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentThemeMode,

          // Routing configurations
          initialRoute: AppRoutes.splash,
          onGenerateRoute: RouteGenerator.generateRoute,
        );
      },
    );
  }
}

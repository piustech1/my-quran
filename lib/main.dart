import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeService = ThemeService();
  await themeService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyQuranApp());
}

class MyQuranApp extends StatelessWidget {
  const MyQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'My Quran',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme, // Light theme is default priority
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

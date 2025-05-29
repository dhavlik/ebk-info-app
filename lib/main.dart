import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/background_task_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Benachrichtigungsservice initialisieren
  await NotificationService.initialize();

  // Request background permissions on Android startup
  await _requestStartupPermissions();

  // Background-Tasks initialisieren (but not start yet - will start in home screen)
  await BackgroundTaskService.initialize();

  runApp(const EBKApp());
}

/// Request necessary permissions on app startup
Future<void> _requestStartupPermissions() async {
  try {
    // Request notification permissions
    final notificationStatus =
        await NotificationService.areNotificationsEnabled();
    if (!notificationStatus) {
      log('Requesting notification permissions...');
      await NotificationService.requestPermissions();
    }

    // Request background permissions on Android
    final backgroundPermissions =
        await BackgroundTaskService.requestBackgroundPermissions();
    if (backgroundPermissions) {
      log('Background permissions granted, ready to start background tasks');
    } else {
      log('Background permissions denied, background tasks will be limited');
    }
  } catch (e) {
    log('Error during startup permission requests: $e');
  }
}

class EBKApp extends StatelessWidget {
  const EBKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EBK App',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('de', ''), // German
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey.shade800,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF37474F), // blueGrey.shade800
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey.shade800,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
      ),
      themeMode: ThemeMode.system, // Automatically follow system preference
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

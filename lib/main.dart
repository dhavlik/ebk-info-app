import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/background_polling_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test comment for pre-commit formatting
  print("Testing pre-commit hooks with intentionally bad formatting");

  // Benachrichtigungsservice initialisieren
  await NotificationService.initialize();

  // Background-Polling starten
  BackgroundPollingService.startPolling();

  runApp(const EBKApp());
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
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
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
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade800,
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

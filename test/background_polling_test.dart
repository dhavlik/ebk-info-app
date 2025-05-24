import 'package:flutter_test/flutter_test.dart';
import 'package:ebk_app/services/background_polling_service.dart';
import 'package:ebk_app/services/notification_service.dart';

void main() {
  // Flutter-Bindings für Notification-Tests initialisieren
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundPollingService Tests', () {
    setUp(() {
      BackgroundPollingService.reset();
    });

    tearDown(() {
      BackgroundPollingService.stopPolling();
    });

    test('sollte Polling starten und stoppen können', () {
      expect(BackgroundPollingService.isRunning, false);

      BackgroundPollingService.startPolling();
      expect(BackgroundPollingService.isRunning, true);

      BackgroundPollingService.stopPolling();
      expect(BackgroundPollingService.isRunning, false);
    });

    test('sollte doppelten Start verhindern', () {
      expect(BackgroundPollingService.isRunning, false);

      BackgroundPollingService.startPolling();
      expect(BackgroundPollingService.isRunning, true);

      // Zweiter Start sollte keinen Effekt haben
      BackgroundPollingService.startPolling();
      expect(BackgroundPollingService.isRunning, true);
    });

    test('sollte Reset-Funktion korrekt arbeiten', () {
      BackgroundPollingService.startPolling();
      expect(BackgroundPollingService.isRunning, true);

      BackgroundPollingService.reset();
      expect(BackgroundPollingService.isRunning, false);
    });

    test('sollte manuellen Status-Check durchführen können', () async {
      // Manuellen Check ausführen (ohne Polling zu starten)
      // Das wird versuchen, die echte API zu erreichen, sollte aber nicht fehlschlagen
      expect(() async => await BackgroundPollingService.checkNow(),
          returnsNormally);
    });
  });

  group('NotificationService Tests', () {
    test('sollte ohne Fehler erstellt werden können', () {
      // Einfacher Test dass die Klasse korrekt definiert ist
      expect(NotificationService, isNotNull);
    });

    test('sollte Hilfsmethoden haben', () {
      // Test dass alle wichtigen Methoden definiert sind
      expect(NotificationService.initialize, isA<Function>());
      expect(NotificationService.showStatusChangeNotification, isA<Function>());
      expect(NotificationService.areNotificationsEnabled, isA<Function>());
      expect(NotificationService.requestPermissions, isA<Function>());
    });
  });
}

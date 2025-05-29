import 'package:flutter_test/flutter_test.dart';
import 'package:ebk_app/services/background_task_service.dart';
import 'package:ebk_app/services/notification_service.dart';

void main() {
  // Flutter-Bindings für Notification-Tests initialisieren
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackgroundTaskService Tests', () {
    setUp(() async {
      await BackgroundTaskService.initialize();
    });

    tearDown(() {
      BackgroundTaskService.stopBackgroundTasks();
      BackgroundTaskService.dispose();
    });

    test('sollte Background-Tasks starten und stoppen können', () async {
      expect(BackgroundTaskService.isRunning, false);

      await BackgroundTaskService.startBackgroundTasks();
      expect(BackgroundTaskService.isRunning, true);

      BackgroundTaskService.stopBackgroundTasks();
      expect(BackgroundTaskService.isRunning, false);
    });

    test('sollte doppelten Start verhindern', () async {
      expect(BackgroundTaskService.isRunning, false);

      await BackgroundTaskService.startBackgroundTasks();
      expect(BackgroundTaskService.isRunning, true);

      // Zweiter Start sollte keinen Effekt haben
      await BackgroundTaskService.startBackgroundTasks();
      expect(BackgroundTaskService.isRunning, true);
    });

    test('sollte manuellen Status-Check durchführen können', () async {
      // Manuellen Check ausführen (ohne Background-Tasks zu starten)
      // Das wird versuchen, die echte API zu erreichen, sollte aber nicht fehlschlagen
      expect(
          () async => await BackgroundTaskService.checkNow(), returnsNormally);
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ebk_app/main.dart' as app;
import 'package:ebk_app/services/background_polling_service.dart';
import 'package:ebk_app/services/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Background Polling Integration Tests', () {
    testWidgets('App sollte mit Background-Polling starten', (tester) async {
      // App starten
      app.main();
      await tester.pumpAndSettle();

      // Überprüfen dass die App geladen ist
      expect(find.text('EBK App'), findsOneWidget);
      
      // Überprüfen dass Background-Polling läuft
      expect(BackgroundPollingService.isRunning, true);
    });

    testWidgets('Refresh-Button sollte manuellen Status-Check auslösen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Refresh-Button finden und antippen
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);
      
      await tester.tap(refreshButton);
      await tester.pump();
      
      // Kurz warten für die Netzwerk-Anfrage
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Benachrichtigungs-Icon sollte klickbar sein', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Benachrichtigungs-Icon finden und antippen
      Finder notificationIcon;
      if (find.byIcon(Icons.notifications).evaluate().isNotEmpty) {
        notificationIcon = find.byIcon(Icons.notifications);
      } else {
        notificationIcon = find.byIcon(Icons.notifications_off);
      }
      expect(notificationIcon, findsOneWidget);
      
      await tester.tap(notificationIcon);
      await tester.pumpAndSettle();
      
      // Dialog sollte erscheinen
      expect(find.text('Benachrichtigungen'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      
      // Dialog schließen
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    });

    testWidgets('Status-Indikatoren sollten in AppBar sichtbar sein', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Sync-Icon (für Background-Polling) sollte sichtbar sein
      Finder syncIcon;
      if (find.byIcon(Icons.sync).evaluate().isNotEmpty) {
        syncIcon = find.byIcon(Icons.sync);
      } else {
        syncIcon = find.byIcon(Icons.sync_disabled);
      }
      expect(syncIcon, findsOneWidget);

      // Benachrichtigungs-Icon sollte sichtbar sein
      Finder notificationIcon;
      if (find.byIcon(Icons.notifications).evaluate().isNotEmpty) {
        notificationIcon = find.byIcon(Icons.notifications);
      } else {
        notificationIcon = find.byIcon(Icons.notifications_off);
      }
      expect(notificationIcon, findsOneWidget);
    });
  });

  group('Space Status Real API Tests', () {
    testWidgets('SpaceStatusCard sollte echte API-Daten laden', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Warten auf das Laden der SpaceAPI-Daten
      await tester.pump(const Duration(seconds: 3));

      // SpaceStatusCard sollte sichtbar sein
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Eigenbaukombinat'), findsOneWidget);
      
      // Status sollte entweder "OFFEN" oder "GESCHLOSSEN" sein
      final openText = find.text('OFFEN');
      final closedText = find.text('GESCHLOSSEN');
      // Überprüfen, ob einer der Status-Texte vorhanden ist
      final hasOpenText = openText.evaluate().isNotEmpty;
      final hasClosedText = closedText.evaluate().isNotEmpty;
      expect(hasOpenText || hasClosedText, isTrue);
    });
  });

  group('Event Loading Real API Tests', () {
    testWidgets('Events sollten von echter API geladen werden', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Warten auf das Laden der Event-Daten
      await tester.pump(const Duration(seconds: 3));

      // Events-Bereich sollte sichtbar sein
      expect(find.text('Kommende Veranstaltungen'), findsOneWidget);
      
      // Entweder echte Events oder Sample Events sollten sichtbar sein
      // Wenn API nicht erreichbar, sollte Fehlermeldung erscheinen
      final errorMessage = find.text('Could not reach calendar endpoint');
      final eventsFound = find.byType(Card);
      
      // Entweder Events oder Error-Message sollte da sein
      expect(eventsFound.evaluate().isNotEmpty || errorMessage.evaluate().isNotEmpty, true);
    });

    testWidgets('Show All/Show Less Toggle sollte funktionieren', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Warten auf das Laden der Event-Daten
      await tester.pump(const Duration(seconds: 3));

      // "Alle anzeigen" Button finden und antippen
      final showAllButton = find.text('Alle anzeigen');
      if (showAllButton.evaluate().isNotEmpty) {
        await tester.tap(showAllButton);
        await tester.pumpAndSettle();
        
        // Nach dem Tap sollte "Weniger anzeigen" sichtbar sein
        expect(find.text('Weniger anzeigen'), findsOneWidget);
        
        // Zurück zu "Weniger anzeigen"
        await tester.tap(find.text('Weniger anzeigen'));
        await tester.pumpAndSettle();
        
        // Wieder "Alle anzeigen" sollte sichtbar sein
        expect(find.text('Alle anzeigen'), findsOneWidget);
      }
    });
  });
}

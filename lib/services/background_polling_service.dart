import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import '../models/space_api_response.dart';
import 'space_api_service.dart';
import 'notification_service.dart';

/// Klasse für Status-Updates, die über den Stream gesendet werden
class SpaceStatusUpdate {
  final SpaceApiResponse spaceData;
  final String? openUntil;
  final DateTime timestamp;

  SpaceStatusUpdate({
    required this.spaceData,
    this.openUntil,
    required this.timestamp,
  });
}

class BackgroundPollingService {
  static Timer? _timer;
  static SpaceApiResponse? _lastResponse;
  static String? _lastOpenUntil;
  static final SpaceApiService _spaceApiService = SpaceApiService();

  // Callback functions for localized strings
  static String Function()? _getStatusChangedTitle;
  static String Function(String status)? _getStatusChangedBody;
  static String Function()? _getOpenUntilChangedTitle;
  static String Function(String time)? _getOpenUntilChangedBody;

  static bool _isRunning = false;

  // Stream Controller für Status-Updates
  static final StreamController<SpaceStatusUpdate> _statusUpdateController =
      StreamController<SpaceStatusUpdate>.broadcast();

  /// Stream für Status-Updates - Widgets können darauf hören
  static Stream<SpaceStatusUpdate> get statusUpdates =>
      _statusUpdateController.stream;

  /// Polling-Intervall: 15 Sekunden im Debug-Modus, 5 Minuten in Production
  static Duration get _pollingInterval =>
      kDebugMode ? const Duration(seconds: 15) : const Duration(minutes: 5);

  /// Startet das automatische Polling (15s debug, 5min production)
  static void startPolling() {
    if (_isRunning) return;

    _isRunning = true;
    final interval = kDebugMode ? '15 seconds' : '5 minutes';
    log('Background Polling Service gestartet (Intervall: $interval)');

    // Sofort einmal ausführen
    _checkSpaceStatus();

    // Timer mit dynamischem Intervall (15s debug, 5min production)
    _timer = Timer.periodic(_pollingInterval, (timer) {
      _checkSpaceStatus();
    });
  }

  /// Stoppt das automatische Polling
  static void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    log('Background Polling Service gestoppt');
  }

  /// Neustarten des Polling-Services (bei App-Resume nützlich)
  static void restartPolling() {
    if (_isRunning) {
      stopPolling();
    }
    startPolling();
  }

  /// Prüft den aktuellen Space-Status und sendet Benachrichtigungen bei Änderungen
  static Future<void> _checkSpaceStatus() async {
    try {
      if (kDebugMode) {
        log('Überprüfe Space-Status (Debug-Modus: team-tfm.com endpoints)...');
      } else {
        log('Überprüfe Space-Status...');
      }

      // Aktuellen Status abrufen
      final response = await _spaceApiService.getSpaceStatus();
      String? openUntil;

      // OpenUntil-Zeit abrufen wenn der Space offen ist
      if (response.state.open) {
        try {
          final openUntilResponse = await _spaceApiService.getOpenUntil();
          openUntil = openUntilResponse.closeTime;
        } catch (e) {
          log('Fehler beim Abrufen der OpenUntil-Zeit: $e');
        }
      }

      // Prüfen ob sich der Status geändert hat
      bool statusChanged = false;
      bool openUntilChanged = false;

      if (_lastResponse != null) {
        statusChanged = _lastResponse!.state.open != response.state.open;
        openUntilChanged = _lastOpenUntil != openUntil;
      }

      // Bei Statusänderung Benachrichtigung senden
      if (statusChanged &&
          _getStatusChangedTitle != null &&
          _getStatusChangedBody != null) {
        final status = response.state.open ? 'OPEN' : 'CLOSED';
        await NotificationService.showStatusChangeNotification(
          title: _getStatusChangedTitle!(),
          body: _getStatusChangedBody!(status),
        );
        log('Status-Benachrichtigung gesendet: $status');
      }

      // Bei OpenUntil-Änderung Benachrichtigung senden (nur wenn offen)
      if (openUntilChanged &&
          response.state.open &&
          openUntil != null &&
          _getOpenUntilChangedTitle != null &&
          _getOpenUntilChangedBody != null) {
        await NotificationService.showStatusChangeNotification(
          title: _getOpenUntilChangedTitle!(),
          body: _getOpenUntilChangedBody!(openUntil),
        );
        log('OpenUntil-Benachrichtigung gesendet: $openUntil');
      }

      // Aktuellen Status speichern
      _lastResponse = response;
      _lastOpenUntil = openUntil;

      // Status-Update über Stream senden (für UI-Updates)
      _statusUpdateController.add(SpaceStatusUpdate(
        spaceData: response,
        openUntil: openUntil,
        timestamp: DateTime.now(),
      ));

      log('Status-Check abgeschlossen: ${response.state.open ? "offen" : "geschlossen"}');
    } catch (e) {
      log('Fehler beim Status-Check: $e');
    }
  }

  /// Gibt zurück ob das Polling aktuell läuft
  static bool get isRunning => _isRunning;

  /// Führt einen manuellen Status-Check durch
  static Future<void> checkNow() async {
    await _checkSpaceStatus();
  }

  /// Setzt den internen Status zurück (für Tests)
  static void reset() {
    stopPolling();
    _lastResponse = null;
    _lastOpenUntil = null;
  }

  /// Ressourcen freigeben (sollte nur beim App-Shutdown aufgerufen werden)
  static void dispose() {
    stopPolling();
    _statusUpdateController.close();
  }

  /// Setzt die Lokalisierungs-Callbacks für Benachrichtigungen
  static void setLocalizationCallbacks({
    required String Function() getStatusChangedTitle,
    required String Function(String status) getStatusChangedBody,
    required String Function() getOpenUntilChangedTitle,
    required String Function(String time) getOpenUntilChangedBody,
  }) {
    _getStatusChangedTitle = getStatusChangedTitle;
    _getStatusChangedBody = getStatusChangedBody;
    _getOpenUntilChangedTitle = getOpenUntilChangedTitle;
    _getOpenUntilChangedBody = getOpenUntilChangedBody;
  }
}

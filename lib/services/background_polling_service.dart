import 'dart:async';
import 'dart:developer';
import '../models/space_api_response.dart';
import 'space_api_service.dart';
import 'notification_service.dart';

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

  /// Startet das automatische Polling alle 5 Minuten
  static void startPolling() {
    if (_isRunning) return;

    _isRunning = true;
    log('Background Polling Service gestartet');

    // Sofort einmal ausführen
    _checkSpaceStatus();

    // Timer für alle 5 Minuten
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
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

  /// Prüft den aktuellen Space-Status und sendet Benachrichtigungen bei Änderungen
  static Future<void> _checkSpaceStatus() async {
    try {
      log('Überprüfe Space-Status...');

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

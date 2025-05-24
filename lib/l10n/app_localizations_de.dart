// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ebk info';

  @override
  String get status => 'Status';

  @override
  String get events => 'Veranstaltungen';

  @override
  String get importantLinks => 'Wichtige Links';

  @override
  String get website => 'Website';

  @override
  String get contact => 'Kontakt';

  @override
  String get email => 'E-Mail';

  @override
  String get address => 'Adresse';

  @override
  String get officialWebsite => 'Offizielle Website';

  @override
  String get phoneContact => 'Telefon Kontakt';

  @override
  String get sendEmail => 'E-Mail schreiben';

  @override
  String get officialLinkCollection => 'Offizielle Linksammlung';

  @override
  String get linkCollectionDescription => 'Sammlung wichtiger EBK-Links';

  @override
  String get showLocationInOpenStreetMap =>
      'Standort in OpenStreetMap anzeigen';

  @override
  String get open => 'offen';

  @override
  String get closed => 'geschlossen';

  @override
  String openUntil(String time) {
    return 'Geöffnet bis: $time';
  }

  @override
  String get eigenbaukombinat => 'Eigenbaukombinat';

  @override
  String get salzwedelGermany => 'Salzwedel, Deutschland';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get couldNotReachCalendarEndpoint =>
      'Kalender-Endpunkt nicht erreichbar';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsDescription =>
      'Benachrichtigungen informieren Sie über Änderungen des EBK-Status. Sie können diese in den Systemeinstellungen aktivieren oder deaktivieren.';

  @override
  String get ok => 'OK';

  @override
  String get requestPermission => 'Berechtigung anfordern';

  @override
  String get ebkStatusChanged => 'EBK Status geändert';

  @override
  String eigenbaukombinatIsNow(String status) {
    return 'Das Eigenbaukombinat ist jetzt $status';
  }

  @override
  String get ebkOpeningTimeChanged => 'EBK Öffnungszeit geändert';

  @override
  String get allDay => 'Ganztägig';

  @override
  String get today => 'Heute';

  @override
  String eventDateTimeFormat(String date, String startTime, String endTime) {
    return 'Am $date von $startTime bis $endTime';
  }

  @override
  String eventTodayTimeFormat(String startTime, String endTime) {
    return 'Heute von $startTime bis $endTime';
  }

  @override
  String eventDateAllDayFormat(String date) {
    return 'Am $date';
  }

  @override
  String get eventTodayAllDayFormat => 'Heute';

  @override
  String get addToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get eventDetails => 'Veranstaltungsdetails';

  @override
  String get eventAddedToCalendar => 'Termin heruntergeladen';

  @override
  String get couldNotAddToCalendar => 'Fehler beim Hinzufügen zum Kalender';
}

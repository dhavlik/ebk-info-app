// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ebk info';

  @override
  String get status => 'Status';

  @override
  String get events => 'Events';

  @override
  String get importantLinks => 'Important Links';

  @override
  String get website => 'Website';

  @override
  String get contact => 'Contact';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get officialWebsite => 'Official Website';

  @override
  String get phoneContact => 'Phone Contact';

  @override
  String get sendEmail => 'Send Email';

  @override
  String get officialLinkCollection => 'Official Link Collection';

  @override
  String get linkCollectionDescription => 'Collection of important EBK links';

  @override
  String get showLocationInOpenStreetMap => 'Show location in OpenStreetMap';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get openUntilLabel => 'Open until';

  @override
  String openUntil(String time) {
    return 'Open until: $time';
  }

  @override
  String get eigenbaukombinat => 'Eigenbaukombinat';

  @override
  String get salzwedelGermany => 'Salzwedel, Germany';

  @override
  String get showAll => 'Show all';

  @override
  String get showLess => 'Show less';

  @override
  String get couldNotReachCalendarEndpoint =>
      'Could not reach calendar endpoint';

  @override
  String get refresh => 'Refresh';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDescription =>
      'Notifications inform you about changes to the EBK status. You can enable or disable them in system settings.';

  @override
  String get ok => 'OK';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get ebkStatusChanged => 'EBK Status Changed';

  @override
  String eigenbaukombinatIsNow(String status) {
    return 'The Eigenbaukombinat is now $status';
  }

  @override
  String get ebkOpeningTimeChanged => 'EBK Opening Time Changed';

  @override
  String get ebkOpenUntilAndStatusChanged =>
      'EBK Status and Opening Time Changed';

  @override
  String openUntilAndStatus(String time, String status) {
    return 'Open until $time - Status: $status';
  }

  @override
  String get allDay => 'All day';

  @override
  String get today => 'Today';

  @override
  String eventDateTimeFormat(String date, String startTime, String endTime) {
    return 'On $date from $startTime to $endTime';
  }

  @override
  String eventTodayTimeFormat(String startTime, String endTime) {
    return 'Today from $startTime to $endTime';
  }

  @override
  String eventDateAllDayFormat(String date) {
    return 'On $date';
  }

  @override
  String get eventTodayAllDayFormat => 'Today';

  @override
  String get addToCalendar => 'Add to Calendar';

  @override
  String get eventDetails => 'Event Details';

  @override
  String get eventAddedToCalendar => 'Event downloaded';

  @override
  String get couldNotAddToCalendar => 'Could not add to calendar';

  @override
  String get documentation => 'Documentation';

  @override
  String get documentationDescription =>
      'Information about areas, tools, machines and more';

  @override
  String get errorLoadingData => 'Error Loading Data';

  @override
  String get retry => 'Retry';

  @override
  String get errorOpeningLink => 'Could not open link';

  @override
  String get category => 'Category';

  @override
  String get subcategory => 'Subcategory';

  @override
  String get overview => 'Overview';

  @override
  String get page => 'Page';
}

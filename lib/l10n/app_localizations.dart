import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'ebk info'**
  String get appTitle;

  /// Status section title
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Events section title
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// Important links section title
  ///
  /// In en, this message translates to:
  /// **'Important Links'**
  String get importantLinks;

  /// Website link title
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Contact link title
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Email link title
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Address link title
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Official website description
  ///
  /// In en, this message translates to:
  /// **'Official Website'**
  String get officialWebsite;

  /// Phone contact description
  ///
  /// In en, this message translates to:
  /// **'Phone Contact'**
  String get phoneContact;

  /// Send email description
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// Official link collection title
  ///
  /// In en, this message translates to:
  /// **'Official Link Collection'**
  String get officialLinkCollection;

  /// Link collection description
  ///
  /// In en, this message translates to:
  /// **'Collection of important EBK links'**
  String get linkCollectionDescription;

  /// Location link description
  ///
  /// In en, this message translates to:
  /// **'Show location in OpenStreetMap'**
  String get showLocationInOpenStreetMap;

  /// Space is open status
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// Space is closed status
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// Space is open until specific time
  ///
  /// In en, this message translates to:
  /// **'Open until: {time}'**
  String openUntil(String time);

  /// The name of the makerspace
  ///
  /// In en, this message translates to:
  /// **'Eigenbaukombinat'**
  String get eigenbaukombinat;

  /// Location of the makerspace
  ///
  /// In en, this message translates to:
  /// **'Salzwedel, Germany'**
  String get salzwedelGermany;

  /// Button to show all events
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// Button to show fewer events
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// Error message when calendar API is unreachable
  ///
  /// In en, this message translates to:
  /// **'Could not reach calendar endpoint'**
  String get couldNotReachCalendarEndpoint;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Notifications dialog title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications dialog description
  ///
  /// In en, this message translates to:
  /// **'Notifications inform you about changes to the EBK status. You can enable or disable them in system settings.'**
  String get notificationsDescription;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Request permission button text
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get requestPermission;

  /// Notification title for status change
  ///
  /// In en, this message translates to:
  /// **'EBK Status Changed'**
  String get ebkStatusChanged;

  /// Notification body for status change
  ///
  /// In en, this message translates to:
  /// **'The Eigenbaukombinat is now {status}'**
  String eigenbaukombinatIsNow(String status);

  /// Notification title for opening time change
  ///
  /// In en, this message translates to:
  /// **'EBK Opening Time Changed'**
  String get ebkOpeningTimeChanged;

  /// Label for all-day events
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// Label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Format for event date and time
  ///
  /// In en, this message translates to:
  /// **'On {date} from {startTime} to {endTime}'**
  String eventDateTimeFormat(String date, String startTime, String endTime);

  /// Format for today's event time
  ///
  /// In en, this message translates to:
  /// **'Today from {startTime} to {endTime}'**
  String eventTodayTimeFormat(String startTime, String endTime);

  /// Format for all-day event date
  ///
  /// In en, this message translates to:
  /// **'On {date}'**
  String eventDateAllDayFormat(String date);

  /// Format for today's all-day event
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventTodayAllDayFormat;

  /// Button to add event to user's calendar
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// Menu item for viewing event details
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// Success message when event is added to calendar
  ///
  /// In en, this message translates to:
  /// **'Event downloaded'**
  String get eventAddedToCalendar;

  /// Error message when adding to calendar fails
  ///
  /// In en, this message translates to:
  /// **'Could not add to calendar'**
  String get couldNotAddToCalendar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

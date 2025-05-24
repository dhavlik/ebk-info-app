import 'dart:convert';
import '../models/event.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:permission_handler/permission_handler.dart';

class ICalService {
  /// Generates iCal content for a single event
  static String generateICalForEvent(Event event) {
    final now = DateTime.now().toUtc();
    final startDateTime = event.date.toUtc();
    final endDateTime =
        event.endTime?.toUtc() ?? startDateTime.add(const Duration(hours: 1));

    // Generate unique UID based on event ID and timestamp
    final uid = '${event.id}@eigenbaukombinat.de';

    // Format dates for iCal (YYYYMMDDTHHMMSSZ)
    String formatDateTime(DateTime dt) {
      return '${dt.year.toString().padLeft(4, '0')}'
          '${dt.month.toString().padLeft(2, '0')}'
          '${dt.day.toString().padLeft(2, '0')}'
          'T'
          '${dt.hour.toString().padLeft(2, '0')}'
          '${dt.minute.toString().padLeft(2, '0')}'
          '${dt.second.toString().padLeft(2, '0')}'
          'Z';
    }

    String formatDate(DateTime dt) {
      return '${dt.year.toString().padLeft(4, '0')}'
          '${dt.month.toString().padLeft(2, '0')}'
          '${dt.day.toString().padLeft(2, '0')}';
    }

    // Escape special characters for iCal and handle line folding
    String escapeText(String text) {
      return text
          .replaceAll('\\', '\\\\')
          .replaceAll(',', '\\,')
          .replaceAll(';', '\\;')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');
    }

    // Fold long lines according to RFC 5545 (max 75 characters)
    String foldLine(String line) {
      if (line.length <= 75) return line;

      final buffer = StringBuffer();
      int index = 0;

      // First line can be 75 characters
      buffer.write(line.substring(0, 75));
      index = 75;

      // Subsequent lines must start with space and can be 74 characters
      while (index < line.length) {
        buffer.write('\r\n '); // CRLF + space for continuation
        final endIndex = (index + 74 < line.length) ? index + 74 : line.length;
        buffer.write(line.substring(index, endIndex));
        index = endIndex;
      }

      return buffer.toString();
    }

    final buffer = StringBuffer();

    // iCal header
    buffer.write('BEGIN:VCALENDAR\r\n');
    buffer.write('VERSION:2.0\r\n');
    buffer.write('PRODID:-//Eigenbaukombinat//EBK App//DE\r\n');
    buffer.write('CALSCALE:GREGORIAN\r\n');
    buffer.write('METHOD:PUBLISH\r\n');

    // Event
    buffer.write('BEGIN:VEVENT\r\n');
    buffer.write(foldLine('UID:$uid') + '\r\n');
    buffer.write(foldLine('DTSTAMP:${formatDateTime(now)}') + '\r\n');

    if (event.isAllDay) {
      buffer.write(
          foldLine('DTSTART;VALUE=DATE:${formatDate(event.date)}') + '\r\n');
      if (event.endTime != null) {
        // For all-day events, end date is exclusive, so add 1 day
        final endDate = event.endTime!.add(const Duration(days: 1));
        buffer.write(
            foldLine('DTEND;VALUE=DATE:${formatDate(endDate)}') + '\r\n');
      } else {
        // Default to 1-day event
        final endDate = event.date.add(const Duration(days: 1));
        buffer.write(
            foldLine('DTEND;VALUE=DATE:${formatDate(endDate)}') + '\r\n');
      }
    } else {
      buffer
          .write(foldLine('DTSTART:${formatDateTime(startDateTime)}') + '\r\n');
      buffer.write(foldLine('DTEND:${formatDateTime(endDateTime)}') + '\r\n');
    }

    buffer.write(foldLine('SUMMARY:${escapeText(event.title)}') + '\r\n');

    // Always include description field, even if empty
    final description =
        event.description.isNotEmpty ? escapeText(event.description) : '';
    buffer.write(foldLine('DESCRIPTION:$description') + '\r\n');

    buffer.write(foldLine('LOCATION:${escapeText(event.location)}') + '\r\n');

    if (event.url != null && event.url!.isNotEmpty) {
      buffer.write(foldLine('URL:${event.url}') + '\r\n');
    }

    buffer.write('STATUS:CONFIRMED\r\n');
    buffer.write('TRANSP:OPAQUE\r\n');
    buffer.write('END:VEVENT\r\n');

    // iCal footer
    buffer.write('END:VCALENDAR\r\n');

    return buffer.toString();
  }

  /// Creates a data URL for downloading the iCal content
  static String createICalDataUrl(Event event) {
    final icalContent = generateICalForEvent(event);
    final encodedContent = base64Encode(utf8.encode(icalContent));
    return 'data:text/calendar;base64,$encodedContent';
  }

  /// Gets the suggested filename for the iCal file
  static String getICalFilename(Event event) {
    // Sanitize the event title for use as filename
    final sanitizedTitle = event.title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();

    final dateStr =
        '${event.date.year}-${event.date.month.toString().padLeft(2, '0')}-${event.date.day.toString().padLeft(2, '0')}';

    return '${dateStr}_${sanitizedTitle}_ebk.ics';
  }

  /// Downloads the iCal file for the event
  static Future<bool> downloadICalFile(Event event) async {
    try {
      // Check if we're on web platform
      if (kIsWeb) {
        // On web, use data URL approach
        final dataUrl = createICalDataUrl(event);
        final Uri uri = Uri.parse(dataUrl);
        return await launchUrl(uri);
      } else {
        // On mobile, check calendar permissions first
        final calendarPermission = await Permission.calendar.status;

        if (calendarPermission.isDenied) {
          // Request calendar permission
          final permissionResult = await Permission.calendar.request();
          if (!permissionResult.isGranted) {
            if (kDebugMode) {
              print('📅 Calendar permission denied');
            }
            // Fall back to alternative method
            return await _fallbackCalendarMethod(event);
          }
        }

        // Use add_2_calendar for native calendar integration
        final calendarEvent = calendar.Event(
          title: event.title,
          description:
              event.description.isNotEmpty ? event.description : event.title,
          location: event.location,
          startDate: event.date,
          endDate: event.endTime ?? event.date.add(const Duration(hours: 1)),
          allDay: event.isAllDay,
        );

        if (kDebugMode) {
          print('📅 Attempting to add event to calendar: ${event.title}');
          print('📅 Event date: ${event.date}');
          print('📅 All day: ${event.isAllDay}');
        }

        final result = await calendar.Add2Calendar.addEvent2Cal(calendarEvent);

        if (kDebugMode) {
          print('📅 Calendar integration result: $result');
        }

        if (result) {
          return true;
        } else {
          // If native calendar fails, try fallback
          return await _fallbackCalendarMethod(event);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('📅 Calendar integration failed: $e');
      }

      // Try fallback method
      return await _fallbackCalendarMethod(event);
    }
  }

  /// Fallback method when native calendar integration fails
  static Future<bool> _fallbackCalendarMethod(Event event) async {
    try {
      if (kDebugMode) {
        print('📅 Attempting fallback: iCal file download');
      }

      final icalContent = generateICalForEvent(event);

      // Create data URL for iCal file
      final dataUrl =
          'data:text/calendar;charset=utf-8,${Uri.encodeComponent(icalContent)}';

      // Try to launch the data URL
      final uri = Uri.parse(dataUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // If data URL fails, try intent-based approach on Android
      return await _tryIntentBasedCalendar(event);
    } catch (e) {
      if (kDebugMode) {
        print('📅 Fallback method also failed: $e');
      }
      return false;
    }
  }

  /// Try Android intent-based calendar integration
  static Future<bool> _tryIntentBasedCalendar(Event event) async {
    try {
      if (kDebugMode) {
        print('📅 Attempting intent-based calendar integration');
      }

      // Create calendar intent URL
      final startTime = event.date.millisecondsSinceEpoch;
      final endTime =
          (event.endTime ?? event.date.add(const Duration(hours: 1)))
              .millisecondsSinceEpoch;

      final intentUrl = 'content://com.android.calendar/events'
          '?title=${Uri.encodeComponent(event.title)}'
          '&description=${Uri.encodeComponent(event.description)}'
          '&eventLocation=${Uri.encodeComponent(event.location)}'
          '&beginTime=$startTime'
          '&endTime=$endTime'
          '&allDay=${event.isAllDay ? 1 : 0}';

      final uri = Uri.parse(intentUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('📅 Intent-based calendar integration failed: $e');
      }
      return false;
    }
  }
}

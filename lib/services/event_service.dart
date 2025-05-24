import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../models/calendar_event.dart';

class EventService {
  static const String _calendarUrl =
      'https://kalender.eigenbaukombinat.de/json/';
  final http.Client? _client;

  EventService({http.Client? client}) : _client = client;

  Future<List<Event>> getEvents({int? limit}) async {
    try {
      final client = _client ?? http.Client();
      final response = await client.get(Uri.parse(_calendarUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final calendarEvents =
            jsonData.map((json) => CalendarEvent.fromJson(json)).toList();

        // Convert to Event objects and filter upcoming events
        final events = calendarEvents
            .map((calendarEvent) => _convertToEvent(calendarEvent))
            .where((event) => event.isUpcoming)
            .toList();

        // Sort by date
        events.sort((a, b) => a.date.compareTo(b.date));

        // Apply limit if specified
        if (limit != null && limit > 0) {
          return events.take(limit).toList();
        }

        return events;
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty list with error indication
      throw Exception('Could not reach calendar endpoint');
    }
  }

  Future<List<Event>> getUpcomingEvents({int limit = 5}) async {
    return getEvents(limit: limit);
  }

  Event _convertToEvent(CalendarEvent calendarEvent) {
    return Event(
      id: calendarEvent.sortDate, // Use sortdate as unique ID
      title: calendarEvent.summary,
      description: _generateDescription(calendarEvent),
      date: calendarEvent.startDateTime,
      endTime: calendarEvent.endDateTime,
      location: 'Eigenbaukombinat Halle',
      url: calendarEvent.url,
      isAllDay: calendarEvent.allDay,
    );
  }

  String _generateDescription(CalendarEvent calendarEvent) {
    // Return empty description since we only display the title/summary
    // Date and time information is handled separately in the UI
    return '';
  }

  // Fallback method for testing/offline mode
  static List<Event> getSampleEvents() {
    final now = DateTime.now();

    return [
      Event(
        id: '1',
        title: 'Sommerfest 2025',
        description:
            'Unser jährliches Sommerfest mit Live-Musik, Essen und Getränken für die ganze Familie.',
        date: DateTime(now.year, 7, 15, 18, 0),
        location: 'EBK Hauptgebäude',
        imageUrl: null,
      ),
      Event(
        id: '2',
        title: 'Workshop: Digitale Kompetenzen',
        description:
            'Lernen Sie die Grundlagen der digitalen Welt kennen. Für Anfänger geeignet.',
        date: DateTime(now.year, now.month + 1, 10, 14, 0),
        location: 'Seminarraum A',
        imageUrl: null,
      ),
    ];
  }
}

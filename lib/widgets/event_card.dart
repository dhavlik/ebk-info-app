import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';
import '../l10n/app_localizations.dart';
import '../services/ical_service.dart';
import 'package:intl/intl.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  String _formatEventDateTime(BuildContext context, Event event) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final eventDate = event.date;
    final isToday = eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;

    if (event.isAllDay) {
      if (isToday) {
        return l10n.eventTodayAllDayFormat;
      } else {
        final dateStr = _formatDate(context, eventDate);
        return l10n.eventDateAllDayFormat(dateStr);
      }
    } else {
      final startTime = _formatTime(eventDate);
      final endTime =
          event.endTime != null ? _formatTime(event.endTime!) : startTime;

      if (isToday) {
        return l10n.eventTodayTimeFormat(startTime, endTime);
      } else {
        final dateStr = _formatDate(context, eventDate);
        return l10n.eventDateTimeFormat(dateStr, startTime, endTime);
      }
    }
  }

  bool _isToday(Event event) {
    final now = DateTime.now();
    final eventDate = event.date;
    return eventDate.year == now.year &&
        eventDate.month == now.month &&
        eventDate.day == now.day;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'de') {
      // German format: dd.mm.yyyy
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } else {
      // English format: yyyy-mm-dd
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(event);
    final dateTimeText = _formatEventDateTime(context, event);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: event.url != null ? () => _launchUrl(event.url!) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // Further reduced whitespace
              Text(
                event.description,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge, // Increased text size
              ),
              const SizedBox(height: 8), // Reduced from 12
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: isToday
                        ? Text(
                            dateTimeText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                          )
                        : Text(
                            dateTimeText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 20, color: Colors.grey),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onSelected: (value) {
                      if (value == 'calendar') {
                        _addToCalendar(context);
                      } else if (value == 'details' && event.url != null) {
                        _launchUrl(event.url!);
                      }
                    },
                    itemBuilder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      final items = <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'calendar',
                          child: Row(
                            children: [
                              const Icon(Icons.event_available, size: 16),
                              const SizedBox(width: 8),
                              Text(l10n.addToCalendar),
                            ],
                          ),
                        ),
                      ];

                      if (event.url != null) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'details',
                            child: Row(
                              children: [
                                const Icon(Icons.open_in_new, size: 16),
                                const SizedBox(width: 8),
                                Text(l10n.eventDetails),
                              ],
                            ),
                          ),
                        );
                      }

                      return items;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently handle URL launch errors
    }
  }

  Future<void> _addToCalendar(BuildContext context) async {
    try {
      final l10n = AppLocalizations.of(context)!;

      final success = await ICalService.downloadICalFile(event);

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.eventAddedToCalendar),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.couldNotAddToCalendar),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotAddToCalendar),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endTime;
  final String location;
  final String? imageUrl;
  final String? url;
  final bool isActive;
  final bool isAllDay;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endTime,
    required this.location,
    this.imageUrl,
    this.url,
    this.isActive = true,
    this.isAllDay = false,
  });

  bool get isUpcoming =>
      date.isAfter(DateTime.now().subtract(const Duration(hours: 24)));

  String get formattedDate {
    return '${date.day}.${date.month}.${date.year}';
  }

  String get formattedTime {
    if (isAllDay) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

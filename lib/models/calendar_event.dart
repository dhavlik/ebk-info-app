class CalendarEvent {
  final bool allDay;
  final String endDate;
  final String endTime;
  final String sortDate;
  final String startDate;
  final String startTime;
  final String summary;
  final String? url;

  CalendarEvent({
    required this.allDay,
    required this.endDate,
    required this.endTime,
    required this.sortDate,
    required this.startDate,
    required this.startTime,
    required this.summary,
    this.url,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      allDay: json['all_day'] ?? false,
      endDate: json['enddate'] ?? '',
      endTime: json['endtime'] ?? '',
      sortDate: json['sortdate'] ?? '',
      startDate: json['startdate'] ?? '',
      startTime: json['starttime'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'],
    );
  }

  DateTime get startDateTime {
    try {
      // Parse German date format "DD.MM.YYYY"
      final dateParts = startDate.split('.');
      if (dateParts.length != 3) return DateTime.now();
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      
      if (allDay) {
        return DateTime(year, month, day);
      }
      
      // Parse time "HH:MM"
      final timeParts = startTime.split(':');
      if (timeParts.length != 2) return DateTime(year, month, day);
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get endDateTime {
    try {
      // Parse German date format "DD.MM.YYYY"
      final dateParts = endDate.split('.');
      if (dateParts.length != 3) return null;
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);
      
      if (allDay) {
        return DateTime(year, month, day, 23, 59);
      }
      
      // Parse time "HH:MM"
      final timeParts = endTime.split(':');
      if (timeParts.length != 2) return null;
      
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }
}

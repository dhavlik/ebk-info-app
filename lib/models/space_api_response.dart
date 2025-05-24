class SpaceApiResponse {
  final String space;
  final String? logo;
  final String? url;
  final Location? location;
  final Contact? contact;
  final State state;

  SpaceApiResponse({
    required this.space,
    this.logo,
    this.url,
    this.location,
    this.contact,
    required this.state,
  });

  factory SpaceApiResponse.fromJson(Map<String, dynamic> json) {
    return SpaceApiResponse(
      space: json['space'] ?? '',
      logo: json['logo'],
      url: json['url'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      contact: json['contact'] != null ? Contact.fromJson(json['contact']) : null,
      state: State.fromJson(json['state']),
    );
  }
}

class Location {
  final String? address;
  final double? lon;
  final double? lat;

  Location({
    this.address,
    this.lon,
    this.lat,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      address: json['address'],
      lon: json['lon']?.toDouble(),
      lat: json['lat']?.toDouble(),
    );
  }
}

class Contact {
  final String? email;
  final String? issueMail;

  Contact({
    this.email,
    this.issueMail,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      email: json['email'],
      issueMail: json['issue_mail'],
    );
  }
}

class State {
  final bool open;
  final int? lastchange;
  final StateIcon? icon;

  State({
    required this.open,
    this.lastchange,
    this.icon,
  });

  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      open: json['open'] ?? false,
      lastchange: json['lastchange'],
      icon: json['icon'] != null ? StateIcon.fromJson(json['icon']) : null,
    );
  }
}

class StateIcon {
  final String? openIcon;
  final String? closedIcon;

  StateIcon({
    this.openIcon,
    this.closedIcon,
  });

  factory StateIcon.fromJson(Map<String, dynamic> json) {
    return StateIcon(
      openIcon: json['open'],
      closedIcon: json['closed'],
    );
  }
}

class OpenUntilResponse {
  final String? closeTime;

  OpenUntilResponse({
    this.closeTime,
  });

  factory OpenUntilResponse.fromJson(Map<String, dynamic> json) {
    return OpenUntilResponse(
      closeTime: json['closetime'],
    );
  }
}

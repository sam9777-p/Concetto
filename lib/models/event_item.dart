class EventItem {
  final String id;
  final String title;
  final String category;
  final String venue;
  final String time;
  final String description;
  final String posterUrl;
  final String date;
  final String prizePool;
  final String teamSize;
  final String rulebookUrl;
  final String registrationUrl;
  final String coordinatorName;
  final String coordinatorContact;
  final bool isFlagship;
  final bool isWatchableOnly;

  final String organizerClub;
  final String coordinatorEmail;
  final String coordinatorPhone;
  final String passwordHash;
  final String updatedAt;

  EventItem({
    required this.id,
    required this.title,
    required this.category,
    required this.venue,
    required this.time,
    required this.description,
    required this.posterUrl,
    this.date = 'Oct 10-12, 2026',
    this.prizePool = '',
    this.teamSize = '1 - 4 Members',
    this.rulebookUrl = '',
    this.registrationUrl = '',
    this.coordinatorName = '',
    this.coordinatorContact = '',
    this.organizerClub = 'Concetto Core Team',
    this.coordinatorEmail = '',
    this.coordinatorPhone = '',
    this.passwordHash = '',
    this.updatedAt = '',
    this.isFlagship = false,
    this.isWatchableOnly = false,
  });

  EventItem copyWith({
    String? id,
    String? title,
    String? category,
    String? venue,
    String? time,
    String? description,
    String? posterUrl,
    String? date,
    String? prizePool,
    String? teamSize,
    String? rulebookUrl,
    String? registrationUrl,
    String? coordinatorName,
    String? coordinatorContact,
    String? organizerClub,
    String? coordinatorEmail,
    String? coordinatorPhone,
    String? passwordHash,
    String? updatedAt,
    bool? isFlagship,
    bool? isWatchableOnly,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      venue: venue ?? this.venue,
      time: time ?? this.time,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      date: date ?? this.date,
      prizePool: prizePool ?? this.prizePool,
      teamSize: teamSize ?? this.teamSize,
      rulebookUrl: rulebookUrl ?? this.rulebookUrl,
      registrationUrl: registrationUrl ?? this.registrationUrl,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorContact: coordinatorContact ?? this.coordinatorContact,
      organizerClub: organizerClub ?? this.organizerClub,
      coordinatorEmail: coordinatorEmail ?? this.coordinatorEmail,
      coordinatorPhone: coordinatorPhone ?? this.coordinatorPhone,
      passwordHash: passwordHash ?? this.passwordHash,
      updatedAt: updatedAt ?? this.updatedAt,
      isFlagship: isFlagship ?? this.isFlagship,
      isWatchableOnly: isWatchableOnly ?? this.isWatchableOnly,
    );
  }

  factory EventItem.fromJson(Map<String, dynamic> json, String id) {
    return EventItem(
      id: id,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      venue: json['venue'] ?? '',
      time: json['time'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      date: json['date'] ?? 'Oct 10-12, 2026',
      prizePool: json['prizePool'] ?? '',
      teamSize: json['teamSize'] ?? '1 - 4 Members',
      rulebookUrl: json['rulebookUrl'] ?? '',
      registrationUrl: json['registrationUrl'] ?? '',
      coordinatorName: json['coordinatorName'] ?? '',
      coordinatorContact: json['coordinatorContact'] ?? '',
      organizerClub: json['organizerClub'] ?? 'Concetto Core Team',
      coordinatorEmail: json['coordinatorEmail'] ?? '',
      coordinatorPhone: json['coordinatorPhone'] ?? (json['coordinatorContact'] ?? ''),
      passwordHash: json['passwordHash'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isFlagship: json['isFlagship'] ?? false,
      isWatchableOnly: json['isWatchableOnly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'venue': venue,
      'time': time,
      'description': description,
      'posterUrl': posterUrl,
      'date': date,
      'prizePool': prizePool,
      'teamSize': teamSize,
      'rulebookUrl': rulebookUrl,
      'registrationUrl': registrationUrl,
      'coordinatorName': coordinatorName,
      'coordinatorContact': coordinatorContact.isNotEmpty ? coordinatorContact : coordinatorPhone,
      'organizerClub': organizerClub,
      'coordinatorEmail': coordinatorEmail,
      'coordinatorPhone': coordinatorPhone.isNotEmpty ? coordinatorPhone : coordinatorContact,
      'passwordHash': passwordHash,
      'updatedAt': updatedAt,
      'isFlagship': isFlagship,
      'isWatchableOnly': isWatchableOnly,
    };
  }
}

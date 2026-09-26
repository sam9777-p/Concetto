class EventItem {
  final String id;
  final String title;
  final String category;
  final List<String> tags;
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
  final bool isStageExperience;

  final String organizerClub;
  final String coordinatorEmail;
  final String coordinatorPhone;
  final String passwordHash;
  final String specificPassword;
  final String updatedAt;
  final bool isVisible;
  final String scheduleBreakdown;
  final List<EventStage> stages;

  EventItem({
    required this.id,
    required this.title,
    required this.category,
    this.tags = const [],
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
    this.specificPassword = '',
    this.updatedAt = '',
    this.isFlagship = false,
    this.isWatchableOnly = false,
    this.isStageExperience = false,
    this.isVisible = true,
    this.scheduleBreakdown = '',
    this.stages = const [],
  });

  EventItem copyWith({
    String? id,
    String? title,
    String? category,
    List<String>? tags,
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
    String? specificPassword,
    String? updatedAt,
    bool? isFlagship,
    bool? isWatchableOnly,
    bool? isStageExperience,
    bool? isVisible,
    String? scheduleBreakdown,
    List<EventStage>? stages,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
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
      specificPassword: specificPassword ?? this.specificPassword,
      updatedAt: updatedAt ?? this.updatedAt,
      isFlagship: isFlagship ?? this.isFlagship,
      isWatchableOnly: isWatchableOnly ?? this.isWatchableOnly,
      isStageExperience: isStageExperience ?? this.isStageExperience,
      isVisible: isVisible ?? this.isVisible,
      scheduleBreakdown: scheduleBreakdown ?? this.scheduleBreakdown,
      stages: stages ?? this.stages,
    );
  }

  factory EventItem.fromJson(Map<String, dynamic> json, String id) {
    List<EventStage> parsedStages = const [];
    if (json['stages'] is List) {
      parsedStages = (json['stages'] as List)
          .whereType<Map>()
          .map((s) => EventStage.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    final isStage = json['isStageExperience'] ?? json['isWatchableOnly'] ?? false;

    return EventItem(
      id: id,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          (json['category'] != null && json['category'].toString().isNotEmpty
              ? [json['category'].toString()]
              : const []),
      venue: json['venue'] ?? '',
      time: json['time'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      date: json['date'] ?? 'Oct 10-12, 2026',
      prizePool: json['prizePool'] ?? '',
      teamSize: json['teamSize'] ?? (isStage ? '' : '1 - 4 Members'),
      rulebookUrl: json['rulebookUrl'] ?? '',
      registrationUrl: json['registrationUrl'] ?? '',
      coordinatorName: json['coordinatorName'] ?? '',
      coordinatorContact: json['coordinatorContact'] ?? '',
      organizerClub: json['organizerClub'] ?? 'Concetto Core Team',
      coordinatorEmail: json['coordinatorEmail'] ?? '',
      coordinatorPhone: json['coordinatorPhone'] ?? (json['coordinatorContact'] ?? ''),
      passwordHash: json['passwordHash'] ?? '',
      specificPassword: json['specificPassword'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isFlagship: json['isFlagship'] ?? false,
      isWatchableOnly: isStage,
      isStageExperience: isStage,
      isVisible: json['isVisible'] ?? true,
      scheduleBreakdown: json['scheduleBreakdown'] ?? '',
      stages: parsedStages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'tags': tags,
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
      'specificPassword': specificPassword,
      'updatedAt': updatedAt,
      'isFlagship': isFlagship,
      'isWatchableOnly': isWatchableOnly || isStageExperience,
      'isStageExperience': isStageExperience,
      'isVisible': isVisible,
      'scheduleBreakdown': scheduleBreakdown,
      'stages': stages.map((s) => s.toJson()).toList(),
    };
  }
}

class EventStage {
  final String name;
  final String date;
  final String time;
  final String venue;
  final String synopsis;

  const EventStage({
    required this.name,
    this.date = '',
    this.time = '',
    this.venue = '',
    this.synopsis = '',
  });

  factory EventStage.fromJson(Map<String, dynamic> json) {
    return EventStage(
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      synopsis: json['synopsis']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'time': time,
      'venue': venue,
      'synopsis': synopsis,
    };
  }
}

class EventItem {
  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final String venue;
  final String time;
  final String startTime;
  final String endTime;
  final String description;
  final String posterUrl;
  final String date;
  final String prizePool;
  final String teamSize;
  final int minTeamSize;
  final int maxTeamSize;
  final bool isOpenRegistration;
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
    String? startTime,
    String? endTime,
    required this.description,
    required this.posterUrl,
    this.date = 'Oct 10-12, 2026',
    this.prizePool = '',
    this.teamSize = '1 - 4 Members',
    this.minTeamSize = 1,
    this.maxTeamSize = 4,
    this.isOpenRegistration = false,
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
  })  : startTime = (startTime != null && startTime.isNotEmpty)
            ? startTime
            : deriveStartTime(time),
        endTime = (endTime != null && endTime.isNotEmpty)
            ? endTime
            : deriveEndTime(time);

  static String deriveStartTime(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(RegExp(r'[-–to]'));
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  static String deriveEndTime(String t) {
    if (t.isEmpty) return '';
    final parts = t.split(RegExp(r'[-–to]'));
    return parts.length > 1 ? parts[1].trim() : '';
  }

  /// Dynamically computed readable team size label
  String get displayTeamSize {
    if (isStageExperience || isWatchableOnly) return '';
    if (isOpenRegistration) return 'Open Registration';
    if (minTeamSize <= 1 && maxTeamSize <= 1) return 'Solo (1 Member)';
    if (minTeamSize == maxTeamSize) return '$minTeamSize Member${minTeamSize > 1 ? 's' : ''}';
    return '$minTeamSize - $maxTeamSize Members';
  }

  EventItem copyWith({
    String? id,
    String? title,
    String? category,
    List<String>? tags,
    String? venue,
    String? time,
    String? startTime,
    String? endTime,
    String? description,
    String? posterUrl,
    String? date,
    String? prizePool,
    String? teamSize,
    int? minTeamSize,
    int? maxTeamSize,
    bool? isOpenRegistration,
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
    final newMin = minTeamSize ?? this.minTeamSize;
    final newMax = maxTeamSize ?? this.maxTeamSize;
    final newIsOpen = isOpenRegistration ?? this.isOpenRegistration;

    String calculatedTeamSize = teamSize ?? this.teamSize;
    if (teamSize == null && (minTeamSize != null || maxTeamSize != null || isOpenRegistration != null)) {
      if (newIsOpen) {
        calculatedTeamSize = 'Open Registration';
      } else if (newMin <= 1 && newMax <= 1) {
        calculatedTeamSize = 'Solo (1 Member)';
      } else if (newMin == newMax) {
        calculatedTeamSize = '$newMin Member${newMin > 1 ? 's' : ''}';
      } else {
        calculatedTeamSize = '$newMin - $newMax Members';
      }
    }

    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      venue: venue ?? this.venue,
      time: time ?? this.time,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      posterUrl: posterUrl ?? this.posterUrl,
      date: date ?? this.date,
      prizePool: prizePool ?? this.prizePool,
      teamSize: calculatedTeamSize,
      minTeamSize: newMin,
      maxTeamSize: newMax,
      isOpenRegistration: newIsOpen,
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
    final rawTeamSize = (json['teamSize'] ?? '').toString();

    // Parse min/max team size and open registration
    bool openReg = json['isOpenRegistration'] ?? false;
    int minT = 1;
    int maxT = 1;

    if (json['minTeamSize'] != null) {
      minT = int.tryParse(json['minTeamSize'].toString()) ?? 1;
    }
    if (json['maxTeamSize'] != null) {
      maxT = int.tryParse(json['maxTeamSize'].toString()) ?? 1;
    }

    // Fallback parsing from rawTeamSize if min/max not explicitly stored
    if (json['minTeamSize'] == null && rawTeamSize.isNotEmpty) {
      final lower = rawTeamSize.toLowerCase();
      if (lower.contains('open') || lower.contains('all') || lower.contains('individual')) {
        openReg = true;
      } else {
        final rangeMatch = RegExp(r'(\d+)\s*[-–to]+\s*(\d+)').firstMatch(rawTeamSize);
        if (rangeMatch != null) {
          minT = int.tryParse(rangeMatch.group(1) ?? '1') ?? 1;
          maxT = int.tryParse(rangeMatch.group(2) ?? '1') ?? 1;
        } else {
          final singleMatch = RegExp(r'(\d+)').firstMatch(rawTeamSize);
          if (singleMatch != null) {
            final val = int.tryParse(singleMatch.group(1) ?? '1') ?? 1;
            minT = val;
            maxT = val;
          }
        }
      }
    }

    if (maxT < minT) maxT = minT;

    String finalTeamSize = rawTeamSize;
    if (finalTeamSize.isEmpty) {
      if (openReg) {
        finalTeamSize = 'Open Registration';
      } else if (minT <= 1 && maxT <= 1) {
        finalTeamSize = 'Solo (1 Member)';
      } else if (minT == maxT) {
        finalTeamSize = '$minT Member${minT > 1 ? 's' : ''}';
      } else {
        finalTeamSize = '$minT - $maxT Members';
      }
    }

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
      startTime: json['startTime'] ?? json['start_time'] ?? '',
      endTime: json['endTime'] ?? json['end_time'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      date: json['date'] ?? 'Oct 10-12, 2026',
      prizePool: json['prizePool'] ?? '',
      teamSize: isStage ? '' : finalTeamSize,
      minTeamSize: minT,
      maxTeamSize: maxT,
      isOpenRegistration: openReg,
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
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'posterUrl': posterUrl,
      'date': date,
      'prizePool': prizePool,
      'teamSize': displayTeamSize,
      'minTeamSize': minTeamSize,
      'maxTeamSize': maxTeamSize,
      'isOpenRegistration': isOpenRegistration,
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

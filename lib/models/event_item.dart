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

  EventItem({
    required this.id,
    required this.title,
    required this.category,
    required this.venue,
    required this.time,
    required this.description,
    required this.posterUrl,
    this.date = 'Oct 10-12, 2025',
    this.prizePool = '',
    this.teamSize = '1 - 4 Members',
    this.rulebookUrl = '',
    this.registrationUrl = '',
    this.coordinatorName = '',
    this.coordinatorContact = '',
    this.isFlagship = false,
  });

  factory EventItem.fromJson(Map<String, dynamic> json, String id) {
    return EventItem(
      id: id,
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      venue: json['venue'] ?? '',
      time: json['time'] ?? '',
      description: json['description'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      date: json['date'] ?? 'Oct 10-12, 2025',
      prizePool: json['prizePool'] ?? '',
      teamSize: json['teamSize'] ?? '1 - 4 Members',
      rulebookUrl: json['rulebookUrl'] ?? '',
      registrationUrl: json['registrationUrl'] ?? '',
      coordinatorName: json['coordinatorName'] ?? '',
      coordinatorContact: json['coordinatorContact'] ?? '',
      isFlagship: json['isFlagship'] ?? false,
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
      'coordinatorContact': coordinatorContact,
      'isFlagship': isFlagship,
    };
  }
}

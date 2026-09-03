class EventItem {
  final String id;
  final String title;
  final String category;
  final String venue;
  final String time;
  final String description;
  final String posterUrl;

  EventItem({
    required this.id,
    required this.title,
    required this.category,
    required this.venue,
    required this.time,
    required this.description,
    required this.posterUrl,
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
    };
  }
}

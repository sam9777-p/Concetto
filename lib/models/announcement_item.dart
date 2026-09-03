class AnnouncementItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json, String id) {
    return AnnouncementItem(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
    };
  }
}

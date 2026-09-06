class AnnouncementItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String tag;
  final String? actionUrl;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.tag = 'GENERAL',
    this.actionUrl,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json, String id) {
    DateTime parsedTimestamp = DateTime.now();
    if (json['timestamp'] != null) {
      try {
        parsedTimestamp = (json['timestamp'] as dynamic).toDate();
      } catch (_) {
        if (json['timestamp'] is String) {
          parsedTimestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
        }
      }
    }

    return AnnouncementItem(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: parsedTimestamp,
      tag: json['tag'] ?? 'GENERAL',
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'tag': tag,
      'actionUrl': actionUrl,
    };
  }
}

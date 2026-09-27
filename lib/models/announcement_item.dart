class AnnouncementItem {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String tag;
  final String? actionUrl;
  final String? imageUrl;
  final String? route;
  final String? contentUrl;

  final bool keepInFeed;
  final bool fcmDispatched;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.tag = 'GENERAL',
    this.actionUrl,
    this.imageUrl,
    this.route,
    this.contentUrl,
    this.keepInFeed = true,
    this.fcmDispatched = false,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json, String id) {
    DateTime parsedTimestamp = DateTime.now();
    final rawTs = json['timestamp'] ?? json['sentAt'] ?? json['createdAt'];
    if (rawTs != null) {
      try {
        parsedTimestamp = (rawTs as dynamic).toDate();
      } catch (_) {
        if (rawTs is String) {
          parsedTimestamp = DateTime.tryParse(rawTs) ?? DateTime.now();
        } else if (rawTs is int) {
          parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
        }
      }
    } else if (json['publishedAtIso'] is String) {
      parsedTimestamp = DateTime.tryParse(json['publishedAtIso'] as String) ?? DateTime.now();
    }

    return AnnouncementItem(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? json['body'] ?? '',
      timestamp: parsedTimestamp,
      tag: json['tag'] ?? json['category'] ?? 'GENERAL',
      actionUrl: json['actionUrl'] ?? json['externalUrl'] ?? json['route'],
      imageUrl: json['imageUrl'] as String?,
      route: json['route'] as String? ?? json['targetRoute'] as String?,
      contentUrl: json['contentUrl'] as String? ?? json['externalUrl'] as String?,
      keepInFeed: json['keepInFeed'] as bool? ?? json['isPublished'] as bool? ?? true,
      fcmDispatched: json['fcmDispatched'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'body': description,
      'timestamp': timestamp,
      'tag': tag,
      'category': tag,
      'actionUrl': actionUrl,
      'imageUrl': imageUrl,
      'route': route,
      'contentUrl': contentUrl,
    };
  }
}

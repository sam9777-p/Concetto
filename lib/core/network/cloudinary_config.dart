/// Configuration for Cloudinary image and document uploads.
/// Uses signed uploads with API Key and API Secret for maximum security and ease of use.
class CloudinaryConfig {
  static const String apiKey = '571655651469164';
  static const String apiSecret = 'hbL-NcjtC87u98k9SWx3C0X9OvQ';

  static const String folderPosters = 'concetto_posters';
  static const String folderRulebooks = 'concetto_rulebooks';
  static const String defaultFolder = 'concetto_events';

  static const String cloudName = 'dcfjykkek';

  /// Returns true since credentials are permanently configured.
  static bool get isConfigured => true;

  /// No-op init retained for compatibility
  static Future<void> init() async {}

  /// Endpoint for image uploads (JPEG, PNG, WebP)
  static String get imageUploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Endpoint for automatic media / document uploads (PDF rulebooks, docs)
  static String get autoUploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

  /// Endpoint for raw document uploads
  static String get rawUploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';

  /// Backward-compatible general upload URL
  static String get uploadUrl => imageUploadUrl;

  /// Folder name alias for backward compatibility
  static String get folder => defaultFolder;

  /// Curated fest poster presets for quick selection
  static const List<Map<String, String>> posterPresets = [
    {
      'title': 'Cyber Robotics',
      'url': 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&q=80',
    },
    {
      'title': 'Hackathon & Coding',
      'url': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&q=80',
    },
    {
      'title': 'Electronics & Hardware',
      'url': 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80',
    },
    {
      'title': 'Combat Bots',
      'url': 'https://images.unsplash.com/photo-1563770660941-20978e870e26?w=800&q=80',
    },
    {
      'title': 'Design & Animation',
      'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&q=80',
    },
    {
      'title': 'Gaming & Esports',
      'url': 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80',
    },
    {
      'title': 'Business & Case Study',
      'url': 'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=800&q=80',
    },
    {
      'title': 'Aeromodelling & Drones',
      'url': 'https://images.unsplash.com/photo-1508614589041-895b88991e3e?w=800&q=80',
    },
  ];
}

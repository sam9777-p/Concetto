/// Configuration for Cloudinary image uploads.
///
/// HOW TO SET UP CLOUDINARY IN 2 MINUTES:
/// 1. Sign up for a free account at https://cloudinary.com
/// 2. In your Dashboard, copy your "Cloud name".
/// 3. Go to Settings (gear icon) -> Upload -> Upload presets -> Add upload preset.
/// 4. Set "Signing Mode" to "Unsigned" and give it a name (e.g., 'concetto_preset').
/// 5. Paste the cloud name and upload preset name below!
class CloudinaryConfig {
  // Replace these with your Cloudinary credentials when ready:
  static const String cloudName = 'demo'; // Replace with your cloud name
  static const String uploadPreset = 'concetto_unsigned'; // Replace with unsigned preset name
  static const String folder = 'concetto_events';

  /// Returns true if the user has configured their own cloud credentials.
  static bool get isConfigured => cloudName.isNotEmpty && cloudName != 'demo';

  /// Cloudinary direct upload endpoint
  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// High-quality fest poster presets for quick selection
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

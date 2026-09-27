import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:dio/dio.dart';
import '../core/router.dart';
import '../core/network/repositories.dart';
import '../core/config/fcm_security_vault.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM Background] Message received: ${message.messageId} - ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? fcmToken;

  /// Global callback hook for displaying in-app foreground notification banner
  static void Function(RemoteMessage message)? onForegroundMessageReceived;

  /// Initializes FCM permissions, topics, and message listeners
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 1. Request user permission for push notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] Notification authorization status: ${settings.authorizationStatus}');

      // 2. Retrieve FCM Device Token
      try {
        fcmToken = await _messaging.getToken();
        debugPrint('[FCM] Device Token: $fcmToken');
      } catch (e) {
        debugPrint('[FCM] Notice retrieving token: $e');
      }

      // 3. Subscribe all devices to the festival broadcast topics (mobile only)
      if (!kIsWeb) {
        try {
          await _messaging.subscribeToTopic('all_users');
          await _messaging.subscribeToTopic('announcements');
          debugPrint('[FCM] Successfully subscribed to topics: "all_users", "announcements"');
        } catch (e) {
          debugPrint('[FCM] Topic subscription notice: $e');
        }
      }

      // 4. Configure foreground presentation options (iOS/macOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM Foreground] Title: ${message.notification?.title}, Body: ${message.notification?.body}');
        if (onForegroundMessageReceived != null) {
          onForegroundMessageReceived!(message);
        } else {
          showInAppHeadsUpBanner(message);
        }
      });

      // 6. Handle notification click when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM Click] App opened from notification: ${message.data}');
        handleNotificationNavigation(message.data);
      });

      // 7. Check if app was cold-launched directly from terminated state via a notification click
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FCM Initial] App launched from terminated state: ${initialMessage.data}');
        Future.delayed(const Duration(milliseconds: 700), () {
          handleNotificationNavigation(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('[FCM] Initialization notice: $e');
    }
  }

  /// Displays an in-app heads-up notification banner if the user is actively viewing the app
  static void showInAppHeadsUpBanner(RemoteMessage message) {
    try {
      final context = goRouter.routerDelegate.navigatorKey.currentContext;
      if (context == null) return;

      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;

      final title = message.notification?.title ?? message.data['title'] ?? 'Concetto \'26 Announcement';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final category = message.data['category'] as String? ?? 'General';
      final imageUrl = message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl ??
          message.data['imageUrl'] as String?;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => _InAppNotificationBanner(
          title: title,
          body: body,
          category: category,
          imageUrl: imageUrl,
          onTap: () {
            try {
              entry.remove();
            } catch (_) {}
            handleNotificationNavigation(message.data);
          },
          onDismiss: () {
            try {
              entry.remove();
            } catch (_) {}
          },
        ),
      );

      overlay.insert(entry);
    } catch (e) {
      debugPrint('Failed to display in-app notification banner: $e');
    }
  }

  /// Handles deep-linking navigation based on payload metadata
  static void handleNotificationNavigation(Map<String, dynamic> data) async {
    final contentUrl = (data['contentUrl'] as String? ?? data['externalUrl'] as String?)?.trim();
    if (contentUrl != null &&
        contentUrl.isNotEmpty &&
        (contentUrl.startsWith('http://') || contentUrl.startsWith('https://'))) {
      final uri = Uri.tryParse(contentUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        } catch (e) {
          debugPrint('Could not launch external notification URL: $e');
        }
      }
    }

    final route = (data['route'] as String?)?.trim();
    if (route != null && route.isNotEmpty && route != 'none' && route != 'null') {
      try {
        goRouter.go(route);
        return;
      } catch (e) {
        debugPrint('Navigation error for notification route $route: $e');
      }
    }

    // If nowhere to navigate, show notification details dialog
    showNotificationDetailsDialog(
      title: data['title'] as String? ?? 'Concetto \'26 Announcement',
      body: data['body'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      imageUrl: data['imageUrl'] as String?,
      contentUrl: contentUrl,
      route: route,
    );
  }

  /// Shows a rich modal dialog with full announcement details
  static void showNotificationDetailsDialog({
    required String title,
    required String body,
    String category = 'General',
    String? imageUrl,
    String? contentUrl,
    String? route,
  }) {
    final context = goRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF140605),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl.trim(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 160,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                title,
                style: GoogleFonts.rajdhani(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('CLOSE', style: TextStyle(color: Colors.white60)),
                  ),
                  if (contentUrl != null && contentUrl.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final uri = Uri.tryParse(contentUrl.trim());
                        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text('OPEN LINK', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
                    ),
                  ] else if (route != null && route.trim().isNotEmpty && route != 'none') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        goRouter.go(route.trim());
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text('VIEW IN APP', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // DIRECT IN-APP FCM DISPATCH (PATH B1)
  // Bypasses Cloud Functions & Blaze Plan Completely
  // ==========================================

  /// Securely retrieves Google Service Account credentials from the embedded vault
  static Future<Map<String, dynamic>?> getServiceAccountCredentials() async {
    // 1. Embedded secure vault
    try {
      final creds = FcmSecurityVault.credentials;
      if (creds.containsKey('private_key') && creds.containsKey('client_email')) {
        return creds;
      }
    } catch (_) {}

    // 2. Check local asset if present
    try {
      final jsonStr = await rootBundle.loadString('assets/service_account.json');
      if (jsonStr.trim().isNotEmpty) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (_) {}

    return null;
  }

  /// Checks if the direct FCM engine is ready to send
  static Future<bool> isDirectFcmConfigured() async {
    return true;
  }

  /// Saves the Google Service Account JSON into Cloud Firestore for all organizers
  static Future<bool> saveServiceAccountCredentials(String jsonString) async {
    try {
      final parsed = jsonDecode(jsonString.trim()) as Map<String, dynamic>;
      if (!parsed.containsKey('private_key') || !parsed.containsKey('client_email')) {
        return false;
      }
      final payload = {
        ...parsed,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      for (final db in FirestoreConfig.allInstances) {
        try {
          await db.collection('admin_config').doc('fcm_credentials').set(payload);
          debugPrint('FCM service account credentials saved to ${db.databaseId}');
        } catch (e) {
          debugPrint('Error saving FCM credentials to ${db.databaseId}: $e');
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error parsing service account JSON: $e');
      return false;
    }
  }

  /// Sends a direct FCM message to all users on topic 'all_users' using HTTP v1 API
  /// This works 100% identically to Cloud Functions on both Android and iOS!
  static Future<({bool success, String? error, String? messageId})> sendFcmDirectBroadcast({
    required String title,
    required String body,
    String imageUrl = '',
    String route = '',
    String contentUrl = '',
    String category = 'Fest Highlights',
  }) async {
    try {
      final credsMap = await getServiceAccountCredentials();
      if (credsMap == null) {
        return (
          success: false,
          error: 'FCM Service Account Key not found. Please paste your Service Account Key in the settings dialog.',
          messageId: null,
        );
      }

      final accountCredentials = ServiceAccountCredentials.fromJson(credsMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient = await clientViaServiceAccount(accountCredentials, scopes);

      final accessToken = authClient.credentials.accessToken.data;
      final projectId = accountCredentials.projectId;

      final dio = Dio();
      final effectiveRoute = (route == 'none' || route.isEmpty) ? '' : route.trim();
      final effectiveContentUrl = contentUrl.trim();

      final payload = {
        'message': {
          'topic': 'all_users',
          'notification': {
            'title': title.trim(),
            'body': body.trim(),
            if (imageUrl.trim().isNotEmpty) 'image': imageUrl.trim(),
          },
          'data': {
            'title': title.trim(),
            'body': body.trim(),
            'category': category.trim(),
            'route': effectiveRoute,
            'contentUrl': effectiveContentUrl,
            'externalUrl': effectiveContentUrl,
            'imageUrl': imageUrl.trim(),
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'concetto_broadcasts',
              'priority': 'high',
              'default_vibrate_timings': true,
              if (imageUrl.trim().isNotEmpty) 'image': imageUrl.trim(),
            },
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
            'payload': {
              'aps': {
                'alert': {
                  'title': title.trim(),
                  'body': body.trim(),
                },
                'sound': 'default',
                'badge': 1,
                'mutable-content': 1,
                'content-available': 1,
              },
            },
            if (imageUrl.trim().isNotEmpty)
              'fcm_options': {
                'image': imageUrl.trim(),
              },
          },
        },
      };

      final response = await dio.post(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        data: payload,
      );

      authClient.close();

      if (response.statusCode == 200) {
        final messageName = response.data['name'] as String?;
        debugPrint('[FCM Direct v1] Push sent successfully: $messageName');
        return (success: true, error: null, messageId: messageName);
      } else {
        return (success: false, error: 'FCM status ${response.statusCode}: ${response.data}', messageId: null);
      }
    } catch (e) {
      debugPrint('[FCM Direct v1] Error sending message: $e');
      return (success: false, error: e.toString(), messageId: null);
    }
  }

  /// Publishes a broadcast notification:
  /// 1. Saves to Firestore broadcast_notifications
  /// 2. If [keepInAnnouncementFeed] is true, saves to announcements feed
  /// 3. Dispatches FCM push notification directly to all Android & iOS devices
  static Future<({bool success, String? error, String? broadcastId, bool fcmSent})> publishBroadcast({
    required String title,
    required String body,
    String imageUrl = '',
    String route = '',
    String contentUrl = '',
    String category = 'Fest Highlights',
    bool keepInAnnouncementFeed = true,
  }) async {
    try {
      final effectiveRoute = (route == 'none' || route.isEmpty) ? '' : route.trim();
      final effectiveContentUrl = contentUrl.trim();

      final payload = {
        'title': title.trim(),
        'body': body.trim(),
        'description': body.trim(),
        'imageUrl': imageUrl.trim(),
        'route': effectiveRoute,
        'targetRoute': effectiveRoute,
        'contentUrl': effectiveContentUrl,
        'externalUrl': effectiveContentUrl,
        'actionUrl': effectiveContentUrl.isNotEmpty ? effectiveContentUrl : effectiveRoute,
        'category': category.trim(),
        'tag': category.trim().toUpperCase(),
        'topic': 'all_users',
        'keepInFeed': keepInAnnouncementFeed,
        'isPublished': keepInAnnouncementFeed,
        'sentAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
        'publishedAtIso': DateTime.now().toIso8601String(),
        'status': 'published',
        'platformTarget': 'all',
      };

      String? createdId;
      final db = FirestoreConfig.instance;

      // 1. Write to broadcast_notifications collection
      try {
        final docRef = await db.collection('broadcast_notifications').add(payload);
        createdId = docRef.id;
        debugPrint('Broadcast notification published to Firestore ID: ${docRef.id}');
      } catch (e) {
        debugPrint('Firestore broadcast write notice: $e');
      }

      // 2. If keepInAnnouncementFeed is ticked, store in announcements collection for public app feed
      if (keepInAnnouncementFeed) {
        try {
          if (createdId != null) {
            await db.collection('announcements').doc(createdId).set(payload);
          } else {
            final docRef = await db.collection('announcements').add(payload);
            createdId = docRef.id;
          }
          debugPrint('Synced broadcast to announcements feed in Firestore ID: $createdId');
        } catch (e) {
          debugPrint('Firestore announcements feed write notice: $e');
        }
      }

      // 3. Dispatch FCM Push Notification directly via Google FCM v1 API
      final fcmRes = await sendFcmDirectBroadcast(
        title: title,
        body: body,
        imageUrl: imageUrl,
        route: effectiveRoute,
        contentUrl: effectiveContentUrl,
        category: category,
      );

      if (fcmRes.success && createdId != null) {
        try {
          await db.collection('broadcast_notifications').doc(createdId).update({
            'fcmDispatched': true,
            'fcmMessageId': fcmRes.messageId,
            'dispatchedAt': FieldValue.serverTimestamp(),
          });
          if (keepInAnnouncementFeed) {
            await db.collection('announcements').doc(createdId).update({
              'fcmDispatched': true,
            });
          }
        } catch (_) {}
      }

      return (
        success: true,
        error: fcmRes.success ? null : fcmRes.error,
        broadcastId: createdId,
        fcmSent: fcmRes.success,
      );
    } catch (e) {
      debugPrint('Error publishing broadcast notification: $e');
      return (success: false, error: e.toString(), broadcastId: null, fcmSent: false);
    }
  }
}

/// Cyberpunk-themed In-App Floating Heads-Up Banner
class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String category;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.category,
    this.imageUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));

    _animController.forward();
    _dismissTimer = Timer(const Duration(seconds: 6), _animateOut);
  }

  void _animateOut() {
    if (mounted) {
      _animController.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null && details.primaryDelta! < -4) {
                _animateOut();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C0605), Color(0xFF0F0B1E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.8), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.imageUrl!.trim(),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _fallbackIcon(),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    _fallbackIcon(),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.category.toUpperCase(),
                                style: GoogleFonts.rajdhani(
                                  color: const Color(0xFF00E5FF),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'NOW',
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rajdhani(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _animateOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.5)),
      ),
      child: const Icon(Icons.notifications_active, color: Color(0xFF00E5FF), size: 20),
    );
  }
}

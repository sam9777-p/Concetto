import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/events/events_screen.dart';
import '../features/events/event_detail_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/auth/profile_screen.dart';
import '../models/event_item.dart';

import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/event_editor_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/store/store_screen.dart';
import '../core/network/mock_data.dart';

class MainWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0403),
          border: Border(
            top: BorderSide(
              color: Color(0x33FF4500),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Store',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined),
              selectedIcon: Icon(Icons.badge),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

final goRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final path = state.uri.path;
    
    // 1. Handle GitHub Pages prefix /Concetto/events...
    if (path.startsWith('/Concetto/events') || path.startsWith('/Concetto')) {
      final id = state.uri.queryParameters['id'];
      if (id != null && id.isNotEmpty) {
        return '/events/$id';
      }
      final sub = path.replaceFirst('/Concetto', '');
      if (sub.startsWith('/events/') && sub.length > 8) {
        return sub;
      }
      return '/events';
    }

    // 2. Handle custom scheme paths like /sparkathon where host was 'events'
    if (path != '/' &&
        path != '/splash' &&
        path != '/admin' &&
        !path.startsWith('/events') &&
        !path.startsWith('/schedule') &&
        !path.startsWith('/store') &&
        !path.startsWith('/merch') &&
        !path.startsWith('/profile') &&
        !path.startsWith('/admin')) {
      final cleanSegment = path.startsWith('/') ? path.substring(1) : path;
      final isEvent = MockData.events.any(
        (e) => e.id.toLowerCase() == cleanSegment.toLowerCase(),
      );
      if (isEvent) {
        return '/events/$cleanSegment';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => const EventEditorScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final event = extra?['event'] as EventItem?;
            final passcode = extra?['passcode'] as String?;
            final isMaster = extra?['isMaster'] as bool? ?? false;
            return EventEditorScreen(
              initialEvent: event,
              authorizedPasscode: passcode,
              isMasterAdmin: isMaster,
            );
          },
        ),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsScreen(),
              routes: [
                GoRoute(
                  path: 'detail',
                  builder: (context, state) {
                    EventItem? event = state.extra as EventItem?;
                    if (event == null) {
                      final id = state.uri.queryParameters['id'];
                      if (id != null && id.isNotEmpty) {
                        try {
                          event = MockData.events.firstWhere(
                            (e) => e.id.toLowerCase() == id.toLowerCase(),
                          );
                        } catch (_) {
                          event = null;
                        }
                      }
                    }
                    if (event == null) {
                      return const EventsScreen();
                    }
                    return EventDetailScreen(event: event);
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) {
                    final id = state.pathParameters['id'];
                    EventItem? event;
                    if (id != null && id.isNotEmpty) {
                      try {
                        event = MockData.events.firstWhere(
                          (e) => e.id.toLowerCase() == id.toLowerCase(),
                        );
                      } catch (_) {
                        event = null;
                      }
                    }
                    if (event == null) {
                      return const EventsScreen();
                    }
                    return EventDetailScreen(event: event);
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (context, state) => const ScheduleScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/store',
              builder: (context, state) => const MerchandiseScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

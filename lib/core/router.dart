import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_theme.dart';
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

class MainWrapper extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainWrapper({super.key, required this.navigationShell});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  final List<int> _tabHistory = [0];
  DateTime? _lastBackPressTime;

  @override
  void didUpdateWidget(covariant MainWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.navigationShell.currentIndex;
    if (_tabHistory.isEmpty || _tabHistory.last != current) {
      _tabHistory.remove(current);
      _tabHistory.add(current);
    }
  }

  void _onDestinationSelected(int index) {
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(
        index,
        initialLocation: true,
      );
      return;
    }

    setState(() {
      _tabHistory.remove(index);
      _tabHistory.add(index);
    });

    widget.navigationShell.goBranch(
      index,
      initialLocation: false,
    );
  }

  void _handleBackPress() {
    // 1. If history has more than 1 tab, step backwards in tab history
    if (_tabHistory.length > 1) {
      setState(() {
        _tabHistory.removeLast(); // pop current tab
        final previousIndex = _tabHistory.last;
        widget.navigationShell.goBranch(previousIndex);
      });
      return;
    }

    // 2. If somehow not on Home (index 0) and history is empty/single, go to Home
    if (widget.navigationShell.currentIndex != 0) {
      setState(() {
        _tabHistory.clear();
        _tabHistory.add(0);
        widget.navigationShell.goBranch(0);
      });
      return;
    }

    // 3. User is on Home (index 0) -> Double-tap to exit Concetto
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.neonOrange, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Press back again to exit Concetto',
                  style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B0704),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0x66FF4500), width: 1),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: widget.navigationShell,
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
            selectedIndex: widget.navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
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
                icon: Icon(Icons.info_outline),
                selectedIcon: Icon(Icons.info),
                label: 'About',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
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

    if (path == '/about') {
      return '/profile';
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
      if (cleanSegment.isNotEmpty && !cleanSegment.contains('/')) {
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
      parentNavigatorKey: _rootNavigatorKey,
      path: '/events/detail',
      builder: (context, state) {
        final EventItem? event = state.extra as EventItem?;
        final id = state.uri.queryParameters['id'];
        if (event == null && (id == null || id.isEmpty)) {
          return const EventsScreen();
        }
        return EventDetailScreen(event: event, eventId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/events/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'];
        final EventItem? event = state.extra as EventItem?;
        if (event == null && (id == null || id.isEmpty)) {
          return const EventsScreen();
        }
        return EventDetailScreen(event: event, eventId: id);
      },
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
            final isDev = extra?['isDev'] as bool? ?? false;
            return EventEditorScreen(
              initialEvent: event,
              authorizedPasscode: passcode,
              isMasterAdmin: isMaster,
              isDeveloperMode: isDev,
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

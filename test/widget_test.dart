import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:concetto/main.dart';

void main() {
  testWidgets('App smoke test - verifies navigation bar items render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the splash screen to navigate immediately to home
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);

    // Verify bottom navigation bar destinations
    expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Events')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Schedule')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('Store')), findsOneWidget);
    expect(find.descendant(of: navBarFinder, matching: find.text('About')), findsOneWidget);

    // Advance time to allow any delayed animations to complete
    await tester.pump(const Duration(seconds: 1));

    // Teardown widget tree so periodic timers in HomeScreen dispose cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}

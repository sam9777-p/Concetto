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
    await tester.pump();

    // Verify bottom navigation bar destinations
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

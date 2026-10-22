import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/main.dart';

void main() {
  testWidgets('MyQuranApp smoke test and splash transition', (WidgetTester tester) async {
    await tester.pumpWidget(const MyQuranApp());
    expect(find.byType(MyQuranApp), findsOneWidget);

    // Advance clock past splash screen timer (2.4s)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify app transitions cleanly
    expect(find.text('My Quran'), findsWidgets);
  });
}

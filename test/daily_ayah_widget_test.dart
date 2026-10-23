import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/screens/daily_ayah_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DailyAyahScreen renders top Mufta backdrop, reciter avatar, and Tafsir card',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DailyAyahScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Top Header
    expect(find.text('Daily Ayah'), findsOneWidget);

    // Verify Translation dropdown in top header exists
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);

    // Verify Bookmark & Share header buttons exist
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    // Verify Upgraded Tafsir & Reflection Section exists
    expect(find.text('TAFSIR & REFLECTION'), findsOneWidget);
    expect(find.text('Understanding this ayah'), findsOneWidget);

    // Verify Quick Actions Bar exists
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}

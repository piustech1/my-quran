import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/screens/daily_ayah_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DailyAyahScreen renders Spotify player, artwork, reflection, and opens Tafsir sheet',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DailyAyahScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Top Header
    expect(find.text('Daily Ayah'), findsOneWidget);

    // Verify Verse of the Day Badge
    expect(find.text('Verse of the Day'), findsOneWidget);

    // Verify Reciter & Audio Controls
    expect(find.text('Reciter'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    // Verify Reflection Panel
    expect(find.text('Reflection'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // Verify Bottom Action Row (Tafsir, Translation, Save)
    expect(find.text('Tafsir'), findsOneWidget);
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Open Tafsir Modal Sheet
    await tester.tap(find.text('Tafsir'));
    await tester.pumpAndSettle();

    // Verify Tafsir Sheet Contents
    expect(find.text('TAFSIR & REFLECTION'), findsOneWidget);
    expect(find.text('Understanding this ayah'), findsOneWidget);
    expect(find.text('Exegesis'), findsOneWidget);
    expect(find.text('Key Lessons'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/main.dart';
import 'package:my_quran/widgets/islamic_star_badge.dart';
import 'package:my_quran/widgets/mushaf_header_banner.dart';

void main() {
  testWidgets('MyQuranApp smoke test and splash transition to HomeDashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyQuranApp());
    expect(find.byType(MyQuranApp), findsOneWidget);

    // Advance clock past splash screen timer (2.4s)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify home dashboard elements are rendered
    expect(find.text('D H U H R'), findsOneWidget);
    expect(find.text("Qur'an"), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
  });

  testWidgets('IslamicStarBadge renders number properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: IslamicStarBadge(number: 7),
        ),
      ),
    );
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('MushafHeaderBanner renders Surah title and Arabic digits', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MushafHeaderBanner(
            surahNameArabic: 'قُرَيْشٍ',
            numberOfAyahs: 4,
            surahNumber: 106,
          ),
        ),
      ),
    );
    expect(find.text('سُورَةُ قُرَيْشٍ'), findsOneWidget);
    expect(find.textContaining('تَرْتِيبُهَا'), findsOneWidget);
    expect(find.textContaining('آيَاتُهَا'), findsOneWidget);
    expect(find.text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'), findsOneWidget);
  });
}

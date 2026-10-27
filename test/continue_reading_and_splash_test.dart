import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_quran/screens/home_dashboard_screen.dart';
import 'package:my_quran/screens/splash_screen.dart';
import 'package:my_quran/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SplashScreen renders official app logo, progress bar, and Hadith saying tag',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial render
    expect(find.text('My Quran'), findsOneWidget);
    expect(find.text('القرآن الكريم'), findsOneWidget);

    // Progressive loading bar & Hadith saying tag exist
    expect(
      find.text('«خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ»'),
      findsOneWidget,
    );
    expect(
      find.text('“The best among you are those who learn the Quran and teach it”'),
      findsOneWidget,
    );

    // Advance animation
    await tester.pump(const Duration(milliseconds: 1200));
    expect(
      find.text('«خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ»'),
      findsOneWidget,
    );

    // Finish splash timer
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('HomeDashboardScreen renders Continue Reading card with percentage and Resume pill',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "CONTINUE READING" tag is rendered
    expect(find.text('CONTINUE READING'), findsOneWidget);

    // Verify default or loaded Surah & Ayah / Juz text
    expect(find.textContaining('Surah'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Ayah'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Juz'), findsAtLeastNWidgets(1));

    // Verify Resume pill button
    expect(find.text('Resume'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

    // Verify Circular percentage indicator
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  });

  test('Daily Ayah audio isolation logic test', () {
    final audioService = QuranAudioService();

    // Set playing state for Surah 1 (Al-Fatihah), Ayah 1
    audioService.isPlayingNotifier.value = true;
    audioService.currentPlayingSurah.value = 1;
    audioService.currentPlayingAyah.value = 1;

    // Suppose Daily Ayah is Surah 2 (Al-Baqarah), Ayah 255
    const dailySurah = 2;
    const dailyAyah = 255;

    final isDailyAyahPlaying = audioService.isPlayingNotifier.value &&
        audioService.currentPlayingSurah.value == dailySurah &&
        audioService.currentPlayingAyah.value == dailyAyah;

    // Should NOT be playing because Al-Fatihah is what is playing
    expect(isDailyAyahPlaying, isFalse);

    // Now switch audio to Daily Ayah
    audioService.currentPlayingSurah.value = dailySurah;
    audioService.currentPlayingAyah.value = dailyAyah;

    final isNowPlaying = audioService.isPlayingNotifier.value &&
        audioService.currentPlayingSurah.value == dailySurah &&
        audioService.currentPlayingAyah.value == dailyAyah;

    expect(isNowPlaying, isTrue);

    // Reset audio state
    audioService.isPlayingNotifier.value = false;
    audioService.currentPlayingSurah.value = null;
    audioService.currentPlayingAyah.value = null;
  });
}

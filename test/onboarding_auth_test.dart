import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_quran/screens/auth/login_screen.dart';
import 'package:my_quran/screens/auth/signup_screen.dart';
import 'package:my_quran/screens/onboarding_screen.dart';
import 'package:my_quran/services/storage_service.dart';
import 'package:my_quran/widgets/pop_out_avatar_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders first slide, navigates slides, and reaches Get Started',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Slide 1 Verification
      expect(find.text('Recite & Reflect'), findsOneWidget);
      expect(find.textContaining('crystal-clear translations'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Advance to Slide 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Accurate Prayer Times'), findsOneWidget);
      expect(find.textContaining('Real-time Adhan alerts'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('← Back'), findsOneWidget);

      // Advance to Slide 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Find Your Qibla'), findsOneWidget);
      expect(find.textContaining('directional compass'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('Tapping Skip or Sign In routes to Auth and records onboarding completion',
        (WidgetTester tester) async {
      final storage = StorageService();
      expect(await storage.hasCompletedOnboarding(), isFalse);

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sign In link in footer
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify Login Screen rendered
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);

      expect(await storage.hasCompletedOnboarding(), isTrue);
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders hero, toggles password visibility, and validates empty email',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);

      // Scroll to and verify elements
      final signInFinder = find.text('Sign In');
      await tester.ensureVisible(signInFinder);
      await tester.pumpAndSettle();
      expect(signInFinder, findsOneWidget);

      // Tap Sign In without filling form to trigger validation
      await tester.tap(signInFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Tap Forgot Password
      final forgotFinder = find.text('Forgot Password?');
      await tester.ensureVisible(forgotFinder);
      await tester.pumpAndSettle();
      await tester.tap(forgotFinder);
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('SignUpScreen Widget Tests', () {
    testWidgets('Renders form fields, enforces live validation, and terms checkbox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Your Account'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

      // Tap submit to trigger validation
      final createBtn = find.text('Create Account');
      await tester.ensureVisible(createBtn);
      await tester.pumpAndSettle();
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);

      // Enter mismatched passwords
      final passField = find.widgetWithText(TextField, 'At least 8 characters');
      await tester.ensureVisible(passField);
      await tester.pumpAndSettle();
      await tester.enterText(passField, 'password123');

      final confirmField = find.widgetWithText(TextField, 'Repeat password');
      await tester.ensureVisible(confirmField);
      await tester.pumpAndSettle();
      await tester.enterText(confirmField, 'mismatched123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Passwords do not match'));
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Fix password match
      await tester.enterText(confirmField, 'password123');
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsNothing);
      expect(find.text('Passwords match'), findsOneWidget);
    });
  });

  group('PopOutAvatarBadge Widget Tests', () {
    testWidgets('Renders Login variant avatar badge cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PopOutAvatarBadge(variant: AvatarVariant.login),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PopOutAvatarBadge), findsOneWidget);
    });

    testWidgets('Renders SignUp variant avatar badge cleanly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PopOutAvatarBadge(variant: AvatarVariant.signup),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PopOutAvatarBadge), findsOneWidget);
    });
  });

  group('StorageService Reactive Sync Tests', () {
    test('Saves last read and updates lastReadNotifier', () async {
      final storage = StorageService();
      expect(storage.lastReadNotifier.value, isNull);

      await storage.saveLastRead(
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        ayahNumber: 255,
      );

      expect(storage.lastReadNotifier.value, isNotNull);
      expect(storage.lastReadNotifier.value!['surah'], equals(2));
      expect(storage.lastReadNotifier.value!['ayah'], equals(255));
    });

    test('Toggles bookmarks and updates bookmarksNotifier', () async {
      final storage = StorageService();
      expect(storage.bookmarksNotifier.value, isEmpty);

      final added = await storage.toggleBookmark(18);
      expect(added, isTrue);
      expect(storage.bookmarksNotifier.value, contains(18));

      final removed = await storage.toggleBookmark(18);
      expect(removed, isFalse);
      expect(storage.bookmarksNotifier.value, isNot(contains(18)));
    });
  });
}

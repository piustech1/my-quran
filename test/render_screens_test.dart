import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_quran/screens/home_dashboard_screen.dart';
import 'package:my_quran/screens/quran_library_screen.dart';
import 'package:my_quran/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> captureWidget({
    required WidgetTester tester,
    required Widget widget,
    required String fileName,
    required Size size,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repaintBoundaryKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: RepaintBoundary(
          key: repaintBoundaryKey,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: widget,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 300));

    await tester.runAsync(() async {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final buffer = byteData.buffer.asUint8List();
          final file = File(
              '/Users/piustech/.gemini/antigravity/brain/8958a1b9-c176-4546-b1ce-ab4c488f4ff2/scratch/$fileName');
          await file.writeAsBytes(buffer);
          // ignore: avoid_print
          print('Successfully captured: $fileName (${buffer.length} bytes)');
        }
      }
    });
  }

  testWidgets('Render HomeDashboardScreen Light & Dark at 412x915',
      (WidgetTester tester) async {
    const mobileSize = Size(412, 915);

    // 1. Light Mode Home
    await captureWidget(
      tester: tester,
      widget: const HomeDashboardScreen(),
      fileName: 'flutter_home_light.png',
      size: mobileSize,
      themeMode: ThemeMode.light,
    );

    // 2. Dark Mode Home
    await captureWidget(
      tester: tester,
      widget: const HomeDashboardScreen(),
      fileName: 'flutter_home_dark.png',
      size: mobileSize,
      themeMode: ThemeMode.dark,
    );

    // 3. Light Mode Quran Library
    await captureWidget(
      tester: tester,
      widget: const QuranLibraryScreen(),
      fileName: 'flutter_quran_light.png',
      size: mobileSize,
      themeMode: ThemeMode.light,
    );

    // 4. Dark Mode Quran Library
    await captureWidget(
      tester: tester,
      widget: const QuranLibraryScreen(),
      fileName: 'flutter_quran_dark.png',
      size: mobileSize,
      themeMode: ThemeMode.dark,
    );
  });
}

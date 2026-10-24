import 'package:flutter/material.dart';
import '../widgets/floating_nav_dock.dart';
import 'home_dashboard_screen.dart';
import 'quran_library_screen.dart';
import 'daily_ayah_screen.dart';
import 'prayers_screen.dart';

/// Primary App Navigation Shell
/// Houses the persistent Floating Liquid Glass Navigation Dock across:
/// - Tab 0: Home Dashboard
/// - Tab 1: Qur'an Library (Surahs, Juz, Pages, Hizbs)
/// - Tab 2: Daily Ayah Experience
/// - Tab 3: Prayers Schedule & Digital Tasbih
///
/// Pushing ReaderScreen opens full-screen without the bottom dock,
/// while popping returns seamlessly with the dock immediately active.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();

  static MainNavigationShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationShellState>();
  }
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index >= 0 && index < 4 && _currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeDashboardScreen(
            isEmbeddedInShell: true,
            onNavigateTab: switchTab,
          ),
          QuranLibraryScreen(
            isEmbeddedInShell: true,
            onNavigateTab: switchTab,
          ),
          DailyAyahScreen(
            isEmbeddedInShell: true,
            onNavigateTab: switchTab,
          ),
          const PrayersScreen(),
        ],
      ),
      bottomNavigationBar: FloatingNavDock(
        currentIndex: _currentIndex,
        onTabSelected: switchTab,
      ),
    );
  }
}

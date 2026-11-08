import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  bool _isInitialized = false;
  bool get isAvailable => _isInitialized;

  FirebaseAuth? _auth;
  FirebaseDatabase? _database;
  StreamSubscription<DatabaseEvent>? _userDataSubscription;

  // Callbacks for live remote sync updates
  Function(Map<String, dynamic> progress)? onRemoteProgressUpdated;
  Function(List<int> surahBookmarks, List<String> ayahBookmarks)? onRemoteBookmarksUpdated;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _auth = FirebaseAuth.instance;
      _database = FirebaseDatabase.instance;

      try {
        _database!.setPersistenceEnabled(true);
      } catch (e) {
        debugPrint('[FirebaseSyncService] Note on persistence: $e');
      }

      _isInitialized = true;
      debugPrint('[FirebaseSyncService] Firebase initialized successfully with Realtime Database.');

      // Listen for auth state changes to attach/detach user listeners
      _auth!.authStateChanges().listen(_handleAuthStateChange);
    } catch (e) {
      debugPrint('[FirebaseSyncService] Operating in resilient local-first mode (Firebase config deferred): $e');
      _isInitialized = false;
    }
  }

  void _handleAuthStateChange(User? user) {
    _userDataSubscription?.cancel();
    if (user != null && _isInitialized && _database != null) {
      _attachUserDataListener(user.uid);
    }
  }

  void _attachUserDataListener(String uid) {
    final userRef = _database!.ref('users/$uid');
    _userDataSubscription = userRef.onValue.listen(
      (DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);

          // Handle reading progress from cloud
          if (map['reading_progress'] is Map && onRemoteProgressUpdated != null) {
            final prog = Map<String, dynamic>.from(map['reading_progress'] as Map);
            onRemoteProgressUpdated!(prog);
          }

          // Handle bookmarks from cloud
          if (map['bookmarks'] is Map && onRemoteBookmarksUpdated != null) {
            final bmarks = Map<String, dynamic>.from(map['bookmarks'] as Map);
            final surahsRaw = bmarks['surahs'];
            final ayahsRaw = bmarks['ayahs'];

            final surahs = <int>[];
            if (surahsRaw is List) {
              for (final item in surahsRaw) {
                final val = int.tryParse(item.toString());
                if (val != null) surahs.add(val);
              }
            }

            final ayahs = <String>[];
            if (ayahsRaw is List) {
              for (final item in ayahsRaw) {
                if (item != null) ayahs.add(item.toString());
              }
            }

            onRemoteBookmarksUpdated!(surahs, ayahs);
          }
        }
      },
      onError: (err) {
        debugPrint('[FirebaseSyncService] Error listening to user data: $err');
      },
    );
  }

  User? get currentUser => _isInitialized ? _auth?.currentUser : null;
  Stream<User?>? get authStateChanges => _isInitialized ? _auth?.authStateChanges() : null;

  // ---------------------------------------------------------------------------
  // Auth Operations
  // ---------------------------------------------------------------------------
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!_isInitialized || _auth == null) return null;
    final cred = await _auth!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _updateLastActive(cred.user?.uid);
    return cred;
  }

  Future<UserCredential?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!_isInitialized || _auth == null) return null;
    final cred = await _auth!.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await _saveInitialProfile(
      uid: cred.user?.uid,
      name: name.trim(),
      email: email.trim(),
    );
    return cred;
  }

  Future<UserCredential?> signInAnonymously() async {
    if (!_isInitialized || _auth == null) return null;
    return await _auth!.signInAnonymously();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_isInitialized || _auth == null) return;
    await _auth!.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    _userDataSubscription?.cancel();
    if (_isInitialized && _auth != null) {
      await _auth!.signOut();
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime Database Sync Operations
  // ---------------------------------------------------------------------------
  Future<void> _saveInitialProfile({
    String? uid,
    required String name,
    required String email,
  }) async {
    if (!_isInitialized || _database == null || uid == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database!.ref('users/$uid/profile').set({
      'name': name,
      'email': email,
      'createdAt': now,
      'lastActive': now,
    });
  }

  Future<void> _updateLastActive(String? uid) async {
    if (!_isInitialized || _database == null || uid == null) return;
    await _database!.ref('users/$uid/profile/lastActive').set(
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> syncReadingProgress({
    required int surahNumber,
    required String surahName,
    required int ayahNumber,
  }) async {
    final uid = currentUser?.uid;
    if (!_isInitialized || _database == null || uid == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database!.ref('users/$uid/reading_progress').set({
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'timestamp': now,
      });
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error syncing reading progress: $e');
    }
  }

  Future<void> syncBookmarks({
    required List<int> surahs,
    required List<String> ayahs,
  }) async {
    final uid = currentUser?.uid;
    if (!_isInitialized || _database == null || uid == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database!.ref('users/$uid/bookmarks').set({
        'surahs': surahs,
        'ayahs': ayahs,
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error syncing bookmarks: $e');
    }
  }

  Future<void> mergeLocalDataToCloud({
    required Map<String, dynamic>? lastRead,
    required List<int> surahBookmarks,
    required List<String> dailyAyahBookmarks,
  }) async {
    final uid = currentUser?.uid;
    if (!_isInitialized || _database == null || uid == null) return;

    try {
      if (lastRead != null) {
        await syncReadingProgress(
          surahNumber: lastRead['surah'] as int? ?? 1,
          surahName: lastRead['surahName'] as String? ?? 'Al-Fatiha',
          ayahNumber: lastRead['ayah'] as int? ?? 1,
        );
      }

      if (surahBookmarks.isNotEmpty || dailyAyahBookmarks.isNotEmpty) {
        await syncBookmarks(
          surahs: surahBookmarks,
          ayahs: dailyAyahBookmarks,
        );
      }
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error merging local data to cloud: $e');
    }
  }

  void dispose() {
    _userDataSubscription?.cancel();
  }
}

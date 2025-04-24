import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // Storage & avatar constants
  static const _avatarBucketName = 'avatars';
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const _avatarUrlExpirySeconds = 60 * 60; // 1 hour

  // ────────────────────────── Singleton
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ────────────────────────── Auth helpers
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ────────────────────────── Breathing session helpers
  /// Records a fixed-length breathing session for the current user
  Future<void> recordBreathingSession() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      await _client.from('breathing_sessions').insert({
        'user_id': userId,
        'duration': 180, // 3 minutes in seconds
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording breathing session: $e');
      rethrow;
    }
  }

  /// Fetches all breathing sessions for the current user
  Future<List<Map<String, dynamic>>> getBreathingSessions() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('breathing_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      debugPrint('Error fetching breathing sessions: $e');
      rethrow;
    }
  }

  /// Returns the total breathing time (sum of durations)
  Future<int> getTotalBreathingTime() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _client
          .from('breathing_sessions')
          .select('duration')
          .eq('user_id', userId);

      return response.fold<int>(
          0, (sum, session) => sum + (session['duration'] as int));
    } catch (e) {
      debugPrint('Error calculating total breathing time: $e');
      rethrow;
    }
  }

  // ────────────────────────── Avatar helpers
  /// Uploads bytes to avatars/{uid}/avatar.jpg, saves path, returns it
  static Future<String> uploadAvatar(Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    if (bytes.length > _maxFileSizeBytes) {
      throw Exception('La imagen es demasiado grande (máx. 5 MB).');
    }

    final filePath = '${user.id}/avatar.jpg';
    debugPrint('Uploading avatar → $filePath');

    try {
      await _client.storage.from(_avatarBucketName).remove([filePath]);
    } catch (_) {}

    await _client.storage.from(_avatarBucketName).uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    await _client.from('profiles').update({
      'avatar_url': filePath,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    return filePath;
  }

  /// Generates a signed URL and appends a cache‑busting parameter **safely**
  /// (uses `&` when a query string already exists).
  static Future<String> getSignedAvatarUrl(String filePath) async {
    final signed = await _client.storage
        .from(_avatarBucketName)
        .createSignedUrl(filePath, _avatarUrlExpirySeconds);

    final cacheBust = 'v=${DateTime.now().millisecondsSinceEpoch}';
    return signed.contains('?') ? '$signed&$cacheBust' : '$signed?$cacheBust';
  }
}

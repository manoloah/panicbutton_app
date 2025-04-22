import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    //required String firstName,
    //required String username,
    //String?  lastName,
    //DateTime? dateOfBirth,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        //'nombre': firstName,
        //'usuario': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> recordBreathingSession() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('breathing_sessions').insert({
        'user_id': userId,
        'duration': 180, // 3 minutes in seconds
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error recording breathing session: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBreathingSessions() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('breathing_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      print('Error fetching breathing sessions: $e');
      rethrow;
    }
  }

  Future<int> getTotalBreathingTime() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('breathing_sessions')
          .select('duration')
          .eq('user_id', userId);

      return response.fold<int>(
          0, (sum, session) => sum + (session['duration'] as int));
    } catch (e) {
      print('Error calculating total breathing time: $e');
      rethrow;
    }
  }

  static Future<String?> uploadAvatar(
    Uint8List bytes, {
    String filename = 'avatar.png', // override if you want a different name
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final filePath = '$userId/$filename'; // avatars/<userId>/avatar.png
      final storage = supabase.storage.from('avatars');

      // ⬇⬇ Upload (overwrites existing file)
      await storage.uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Return the public URL so you can store it in the profiles row
      return storage.getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}

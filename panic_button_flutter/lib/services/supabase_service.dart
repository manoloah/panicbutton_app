import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;
  static const _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const _avatarBucketName = 'avatars';

  // Singleton pattern
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

  static Future<String> uploadAvatar(Uint8List bytes) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate file size
      if (bytes.length > _maxFileSizeBytes) {
        throw Exception('La imagen es demasiado grande. Máximo 5MB permitido.');
      }

      // Create a path that matches the RLS policy structure
      final fileName = 'avatar.jpg';
      final filePath = '${user.id}/$fileName';
      debugPrint('Uploading avatar to path: $filePath');

      // First, try to remove existing avatar
      try {
        final response = await _client.storage
            .from(_avatarBucketName)
            .list();
            
        final existingFiles = response.where(
          (file) => file.name.startsWith('${user.id}/'),
        ).toList();
            
        if (existingFiles.isNotEmpty) {
          await _client.storage.from(_avatarBucketName).remove([filePath]);
          debugPrint('Removed existing avatar');
        }
      } catch (e) {
        debugPrint('No existing avatar to remove or error: $e');
      }

      // Upload to Supabase Storage
      await _client.storage
          .from(_avatarBucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      debugPrint('Upload successful');

      // Get the public URL
      final publicUrl = _client.storage.from(_avatarBucketName).getPublicUrl(filePath);
      
      // Add cache-busting parameter
      final urlWithCacheBust = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('Generated URL with cache bust: $urlWithCacheBust');

      // Update the profile with the new avatar URL
      await _client.from('profiles').update({
        'avatar_url': publicUrl, // Store clean URL in database
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      
      return urlWithCacheBust;
    } catch (e, stackTrace) {
      debugPrint('Error uploading avatar: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _supabase = Supabase.instance.client;

  Future<void> recordBreathingSession() async {
    try {
      await _supabase.from('breathing_sessions').insert({
        'user_id': _supabase.auth.currentUser?.id,
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
      final response = await _supabase
          .from('breathing_sessions')
          .select()
          .eq('user_id', _supabase.auth.currentUser?.id)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      print('Error fetching breathing sessions: $e');
      rethrow;
    }
  }

  Future<int> getTotalBreathingTime() async {
    try {
      final response = await _supabase
          .from('breathing_sessions')
          .select('duration')
          .eq('user_id', _supabase.auth.currentUser?.id);
      
      return response.fold<int>(0, (sum, session) => sum + (session['duration'] as int));
    } catch (e) {
      print('Error calculating total breathing time: $e');
      rethrow;
    }
  }
} 
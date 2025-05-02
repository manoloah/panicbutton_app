import 'package:panic_button_flutter/models/breathwork_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BreathworkService {
  static final _client = Supabase.instance.client;

  // ────────────────────────── Singleton
  static final BreathworkService _instance = BreathworkService._internal();
  factory BreathworkService() => _instance;
  BreathworkService._internal();

  /// Get all breathing goals from the database
  Future<List<Goal>> getGoals() async {
    final response = await _client.from('goals').select().order('display_name');

    return response.map<Goal>((json) => Goal.fromJson(json)).toList();
  }

  /// Get a breathing step by ID
  Future<Step?> getStep(String id) async {
    final response = await _client.from('steps').select().eq('id', id).single();

    return Step.fromJson(response);
  }

  /// Get a pattern by ID
  Future<Pattern?> getPattern(String id) async {
    final response =
        await _client.from('patterns').select().eq('id', id).single();

    return Pattern.fromJson(response);
  }

  /// Get all steps for a pattern
  Future<List<Map<String, dynamic>>> getPatternSteps(String patternId) async {
    final response = await _client.from('pattern_steps').select('''
          *,
          step: steps(*)
        ''').eq('pattern_id', patternId).order('position');

    return response;
  }

  /// Get all routines for a specific goal
  Future<List<Routine>> getRoutinesByGoal(String goalId) async {
    final response = await _client
        .from('routines')
        .select()
        .eq('goal_id', goalId)
        .eq('is_public', true)
        .order('name');

    return response.map<Routine>((json) => Routine.fromJson(json)).toList();
  }

  /// Get all items for a routine
  Future<List<Map<String, dynamic>>> getRoutineItems(String routineId) async {
    final response = await _client.from('routine_items').select('''
          *,
          pattern: patterns(*),
          step: steps(*)
        ''').eq('routine_id', routineId).order('position');

    return response;
  }

  /// Get the default routine (4-6 Calming)
  Future<Routine?> getDefaultRoutine() async {
    final response = await _client
        .from('routines')
        .select()
        .eq('name', 'Calma Rápida 4 min')
        .limit(1)
        .single();

    return Routine.fromJson(response);
  }

  /// Update a user's routine status (track usage)
  Future<void> updateRoutineStatus(String routineId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('user_routine_status').upsert({
        'user_id': user.id,
        'routine_id': routineId,
        'last_run': DateTime.now().toIso8601String(),
        'total_runs': 1, // Will be incremented by function
      }, onConflict: 'user_id,routine_id');

      // Use the correct parameter names for the function
      await _client.rpc('increment_total_runs',
          params: {'p_routine_id': routineId, 'p_user_id': user.id});
    } catch (e) {
      // Silently handle error if function doesn't exist
      print('Error updating routine status: $e');
    }
  }
}

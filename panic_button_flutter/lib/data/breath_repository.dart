import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/models/breath_models.dart';

class BreathRepository {
  final SupabaseClient _supabase;

  BreathRepository(this._supabase);

  Future<List<GoalModel>> getGoals() async {
    try {
      final response =
          await _supabase.from('breathing_goals').select().order('sort_order');

      final goals =
          (response as List).map((json) => GoalModel.fromJson(json)).toList();
      debugPrint('✅ Fetched ${goals.length} goals');
      return goals;
    } catch (e) {
      debugPrint('❌ Error fetching goals: $e');
      return [];
    }
  }

  Future<List<PatternModel>> getPatternsByGoal(String goalId) async {
    try {
      final response = await _supabase
          .from('breathing_patterns')
          .select('*, breathing_pattern_steps!inner(*, breathing_steps(*))')
          .eq('goal_id', goalId)
          .order('name');

      final patterns = <PatternModel>[];
      final patternMap = <String, List<PatternStepModel>>{};

      // First pass: collect all patterns and organize steps by pattern ID
      for (final item in response as List) {
        try {
          // Extract the pattern data
          final patternId = item['id'] as String;

          // Create the pattern if not already created
          if (!patternMap.containsKey(patternId)) {
            // Safely create the pattern model directly
            final pattern = PatternModel(
              id: item['id'] as String? ?? '',
              name: item['name'] as String? ?? '',
              goalId: item['goal_id'] as String? ?? '',
              recommendedMinutes: item['recommended_minutes'] as int? ?? 5,
              cycleSecs: item['cycle_secs'] as int? ?? 8,
              slug: item['slug'] as String? ?? '',
              description: item['description'] as String?,
              createdAt: item['created_at'] != null
                  ? DateTime.parse(item['created_at'] as String)
                  : null,
            );
            patterns.add(pattern);
            patternMap[patternId] = [];
          }

          // Process the steps with direct safety checks
          if (item['breathing_pattern_steps'] != null) {
            for (final stepData in item['breathing_pattern_steps'] as List) {
              if (stepData != null && stepData['breathing_steps'] != null) {
                final stepsData =
                    Map<String, dynamic>.from(stepData['breathing_steps']);

                try {
                  // Create the step with safe defaults
                  final step = StepModel(
                    id: stepsData['id'] as String? ?? '',
                    inhaleSecs: stepsData['inhale_secs'] as int? ?? 4,
                    inhaleMethod:
                        stepsData['inhale_method'] as String? ?? 'nose',
                    holdInSecs: stepsData['hold_in_secs'] as int? ?? 0,
                    exhaleSecs: stepsData['exhale_secs'] as int? ?? 4,
                    exhaleMethod:
                        stepsData['exhale_method'] as String? ?? 'nose',
                    holdOutSecs: stepsData['hold_out_secs'] as int? ?? 0,
                    cueText: stepsData['cue_text'] as String? ?? 'Respira',
                  );

                  // Create the pattern step
                  final patternStep = PatternStepModel(
                    id: stepData['id'] as String? ?? '',
                    patternId: stepData['pattern_id'] as String? ?? '',
                    stepId: stepData['step_id'] as String? ?? '',
                    position: stepData['position'] as int? ?? 0,
                    repetitions: stepData['repetitions'] as int? ?? 1,
                    step: step,
                  );

                  patternMap[patternId]!.add(patternStep);
                } catch (e) {
                  debugPrint('❌ Error creating step: $e');
                  continue;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error processing pattern data: $e');
          continue;
        }
      }

      // Second pass: update patterns with their steps
      for (int i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        final steps = patternMap[pattern.id] ?? [];

        // Sort steps by position
        steps.sort((a, b) => a.position.compareTo(b.position));

        // Update pattern with steps using copyWith
        patterns[i] = pattern.copyWith(steps: steps);
      }

      debugPrint('✅ Fetched ${patterns.length} patterns for goal: $goalId');
      return patterns;
    } catch (e) {
      debugPrint('❌ Error fetching patterns: $e');
      return [];
    }
  }

  Future<List<ExpandedStep>> expandPattern(String patternId,
      {required int targetMinutes}) async {
    try {
      // Get pattern with steps
      final patternData = await _supabase
          .from('breathing_patterns')
          .select('*, breathing_pattern_steps!inner(*, breathing_steps(*))')
          .eq('id', patternId)
          .single();

      final patternSteps = patternData['breathing_pattern_steps'] as List;
      final cycleSecs = patternData['cycle_secs'] as int;

      // Calculate how many times to repeat the pattern
      final targetSeconds = targetMinutes * 60;
      final repetitions = (targetSeconds / cycleSecs).ceil();

      final allSteps = <ExpandedStep>[];

      // If no valid steps, create default steps based on pattern name
      if (patternSteps.isEmpty ||
          patternSteps.every((s) => s['breathing_steps'] == null)) {
        // Extract breathing times from pattern name if possible
        final pattern = patternData['name'] as String;

        // Check if pattern contains numbers like "4-6" or "Box 4-4-4-4"
        RegExp numberPattern =
            RegExp(r'(\d+)(?:-(\d+))?(?:-(\d+))?(?:-(\d+))?');
        final match = numberPattern.firstMatch(pattern);

        if (match != null) {
          int inhaleTime = int.tryParse(match.group(1) ?? '4') ?? 4;
          int exhaleTime =
              int.tryParse(match.group(2) ?? inhaleTime.toString()) ??
                  inhaleTime;
          int holdInTime = int.tryParse(match.group(3) ?? '0') ?? 0;
          int holdOutTime = int.tryParse(match.group(4) ?? '0') ?? 0;

          // Create a default step
          final defaultStep = ExpandedStep(
            cueText: pattern,
            inhaleSecs: inhaleTime,
            exhaleSecs: exhaleTime,
            holdInSecs: holdInTime,
            holdOutSecs: holdOutTime,
            inhaleMethod: 'nose',
            exhaleMethod: 'nose',
          );

          // Add steps to match the requested duration
          final cycleTime = inhaleTime + exhaleTime + holdInTime + holdOutTime;
          final stepCount = (targetSeconds / cycleTime).ceil();

          for (int i = 0; i < stepCount; i++) {
            allSteps.add(defaultStep);
          }

          debugPrint(
              '✅ Created ${allSteps.length} default steps for pattern $pattern');
          return allSteps;
        }
      }

      // Convert to expanded steps (use regular implementation)
      for (var i = 0; i < repetitions; i++) {
        for (final stepData in patternSteps) {
          if (stepData != null && stepData['breathing_steps'] != null) {
            try {
              final stepsData =
                  Map<String, dynamic>.from(stepData['breathing_steps']);
              // Add safe defaults for any missing values
              stepsData['inhale_secs'] ??= 4;
              stepsData['exhale_secs'] ??= 4;
              stepsData['hold_in_secs'] ??= 0;
              stepsData['hold_out_secs'] ??= 0;
              stepsData['inhale_method'] ??= 'nose';
              stepsData['exhale_method'] ??= 'nose';
              stepsData['cue_text'] ??= 'Respira';

              final step = StepModel.fromJson(stepsData);
              final stepRepetitions = stepData['repetitions'] as int? ?? 1;

              for (var r = 0; r < stepRepetitions; r++) {
                allSteps.add(ExpandedStep.fromStep(step));
              }
            } catch (stepError) {
              // Skip invalid steps
              continue;
            }
          }
        }
      }

      // If we couldn't create any steps, create a default 4-4 pattern
      if (allSteps.isEmpty) {
        final defaultStep = ExpandedStep(
          cueText: 'Respira',
          inhaleSecs: 4,
          exhaleSecs: 4,
          holdInSecs: 0,
          holdOutSecs: 0,
          inhaleMethod: 'nose',
          exhaleMethod: 'nose',
        );

        // Add steps to match the requested duration
        final stepCount = (targetSeconds / 8).ceil(); // 8 = 4+4

        for (int i = 0; i < stepCount; i++) {
          allSteps.add(defaultStep);
        }
      }

      debugPrint('✅ Expanded to ${allSteps.length} steps');
      return allSteps;
    } catch (e) {
      debugPrint('❌ Error expanding pattern: $e');

      // Fallback to default pattern if anything fails
      final defaultStep = ExpandedStep(
        cueText: 'Respira',
        inhaleSecs: 4,
        exhaleSecs: 4,
        holdInSecs: 0,
        holdOutSecs: 0,
        inhaleMethod: 'nose',
        exhaleMethod: 'nose',
      );

      final stepCount = (targetMinutes * 60 / 8).ceil(); // 8 = 4+4
      final fallbackSteps = List.generate(stepCount, (_) => defaultStep);

      debugPrint(
          '⚠️ Using fallback pattern with ${fallbackSteps.length} steps');
      return fallbackSteps;
    }
  }

  Future<String?> logPatternRun(String patternId, int targetMinutes) async {
    // Wrap the entire function in a try-catch to ensure it never crashes the app
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ Cannot log pattern run: User not authenticated');
        return null; // Silently return if user is not authenticated
      }

      // Record the start of the breathing activity with explicit values
      final expectedDurationSeconds = targetMinutes * 60;
      final activityData = {
        'user_id': userId,
        'pattern_id': patternId,
        'expected_duration_seconds': expectedDurationSeconds,
        'completed': false,
        'duration_seconds': 0, // Initial duration is always 0
      };

      debugPrint(
          '🔄 Creating breathing activity for pattern: $patternId, expected duration: $expectedDurationSeconds seconds');

      try {
        final activityResult = await _supabase
            .from('breathing_activity')
            .insert(activityData)
            .select('id')
            .single();

        // Store the activity ID for later update
        final activityId = activityResult['id'] as String;
        debugPrint(
            '✅ Created breathing activity record: $activityId for pattern: $patternId');

        // Verify the record was created
        final checkResult = await _supabase
            .from('breathing_activity')
            .select('id, pattern_id, expected_duration_seconds')
            .eq('id', activityId)
            .single();

        debugPrint(
            '✓ Verified activity creation: ${checkResult['id']} - Pattern: ${checkResult['pattern_id']}, Expected duration: ${checkResult['expected_duration_seconds']}s');

        return activityId;
      } catch (insertError) {
        debugPrint('⚠️ Error inserting breathing activity: $insertError');
        // Log full error details to help debug RLS issues
        if (insertError is PostgrestException) {
          final pgError = insertError;
          debugPrint('  - Message: ${pgError.message}');
          debugPrint('  - Code: ${pgError.code}');
          debugPrint('  - Details: ${pgError.details}');
          debugPrint('  - Hint: ${pgError.hint}');
        }
        rethrow; // Re-throw so the caller can handle the error
      }
    } catch (e) {
      // Just silently log but don't rethrow - pattern logging is not essential
      debugPrint('⚠️ Error in logPatternRun: $e');
    }

    return null;
  }

  // Add a new method to complete a breathing activity
  Future<void> completeBreathingActivity(
      String activityId, int durationSeconds, bool completed) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint(
            '⚠️ Cannot complete breathing activity: User not authenticated');
        return;
      }

      // Get existing record to log details
      final existingRecord = await _supabase
          .from('breathing_activity')
          .select('pattern_id, expected_duration_seconds')
          .eq('id', activityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        final patternId = existingRecord['pattern_id'] as String;
        debugPrint(
            '🔄 Updating breathing activity: $activityId for pattern: $patternId, duration: $durationSeconds seconds, completed: $completed');
      }

      // Update the breathing activity with the actual duration
      await _supabase
          .from('breathing_activity')
          .update({
            'duration_seconds': durationSeconds,
            'completed': completed,
          })
          .eq('id', activityId)
          .eq('user_id', userId); // Additional safety check

      debugPrint(
          '✅ Updated breathing activity: $activityId with duration: $durationSeconds seconds');
    } catch (e) {
      debugPrint('⚠️ Error completing breathing activity: $e');
    }
  }

  // Add a method to get the current breathing activity
  Future<String?> getCurrentBreathingActivity() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return null;
      }

      // Get the most recent incomplete activity
      final result = await _supabase
          .from('breathing_activity')
          .select('id')
          .eq('user_id', userId)
          .eq('completed', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return result != null ? result['id'] as String : null;
    } catch (e) {
      debugPrint('⚠️ Error getting current breathing activity: $e');
      return null;
    }
  }

  Future<PatternModel?> getPatternBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('breathing_patterns')
          .select('*, breathing_pattern_steps!inner(*, breathing_steps(*))')
          .eq('slug', slug)
          .limit(1);

      if ((response as List).isEmpty) {
        return null;
      }

      final patternData = response[0];
      final patternSteps = patternData['breathing_pattern_steps'] as List;

      // Create the pattern
      final pattern = PatternModel(
        id: patternData['id'] as String? ?? '',
        name: patternData['name'] as String? ?? '',
        goalId: patternData['goal_id'] as String? ?? '',
        recommendedMinutes: patternData['recommended_minutes'] as int? ?? 5,
        cycleSecs: patternData['cycle_secs'] as int? ?? 8,
        slug: patternData['slug'] as String? ?? '',
        description: patternData['description'] as String?,
        createdAt: patternData['created_at'] != null
            ? DateTime.parse(patternData['created_at'] as String)
            : null,
      );

      // Process steps
      final steps = <PatternStepModel>[];

      for (final stepData in patternSteps) {
        if (stepData != null && stepData['breathing_steps'] != null) {
          final stepsData =
              Map<String, dynamic>.from(stepData['breathing_steps']);

          try {
            // Create the step with safe defaults
            final step = StepModel(
              id: stepsData['id'] as String? ?? '',
              inhaleSecs: stepsData['inhale_secs'] as int? ?? 4,
              inhaleMethod: stepsData['inhale_method'] as String? ?? 'nose',
              holdInSecs: stepsData['hold_in_secs'] as int? ?? 0,
              exhaleSecs: stepsData['exhale_secs'] as int? ?? 4,
              exhaleMethod: stepsData['exhale_method'] as String? ?? 'nose',
              holdOutSecs: stepsData['hold_out_secs'] as int? ?? 0,
              cueText: stepsData['cue_text'] as String? ?? 'Respira',
            );

            // Create the pattern step
            final patternStep = PatternStepModel(
              id: stepData['id'] as String? ?? '',
              patternId: stepData['pattern_id'] as String? ?? '',
              stepId: stepData['step_id'] as String? ?? '',
              position: stepData['position'] as int? ?? 0,
              repetitions: stepData['repetitions'] as int? ?? 1,
              step: step,
            );

            steps.add(patternStep);
          } catch (e) {
            debugPrint('❌ Error creating step: $e');
            continue;
          }
        }
      }

      // Sort steps by position
      steps.sort((a, b) => a.position.compareTo(b.position));

      // Return the pattern with its steps
      return pattern.copyWith(steps: steps);
    } catch (e) {
      debugPrint('❌ Error fetching pattern by slug: $e');
      return null;
    }
  }
}

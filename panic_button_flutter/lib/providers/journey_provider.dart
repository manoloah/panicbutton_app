import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panic_button_flutter/models/journey_level.dart';

/// Provider for managing the breathing journey progress and unlocking logic
class JourneyProvider with ChangeNotifier {
  /// Supabase client for database operations
  final SupabaseClient _supabase = Supabase.instance.client;

  /// List of all journey levels
  List<JourneyLevel> _allLevels = [];

  /// Current user's highest unlocked level (1-indexed)
  int _currentLevelId = 1;

  /// Progress percentage toward unlocking the next level (0.0 to 1.0)
  double _progressPercent = 0.0;

  /// User's average BOLT score from the last 7 days
  double _averageBolt = 0.0;

  /// User's total minutes of breathing practice in the last 7 days
  int _weeklyMinutes = 0;

  /// Loading state flag
  bool _isLoading = true;

  /// Error message, if any
  String? _errorMessage;

  /// Cache for pattern names by slug
  final Map<String, String> _patternNameCache = {};

  /// Initialize the provider and load data
  JourneyProvider() {
    init();
  }

  /// Get all journey levels
  List<JourneyLevel> get allLevels => _allLevels;

  /// Get only the levels that user has unlocked
  List<JourneyLevel> get unlockedLevels =>
      _allLevels.where((level) => level.id <= _currentLevelId).toList();

  /// Get the current level
  JourneyLevel? get currentLevel => _allLevels.isEmpty
      ? null
      : _allLevels.firstWhere((level) => level.id == _currentLevelId);

  /// Get the next level to unlock (null if at max level)
  JourneyLevel? get nextLevel => _currentLevelId < _allLevels.length
      ? _allLevels.firstWhere((level) => level.id == _currentLevelId + 1)
      : null;

  /// Get progress percentage toward next level
  double get progressPercent => _progressPercent;

  /// Get user's average BOLT score from last 7 days
  double get averageBolt => _averageBolt;

  /// Get user's weekly minutes practiced
  int get weeklyMinutes => _weeklyMinutes;

  /// Check if provider is loading data
  bool get isLoading => _isLoading;

  /// Get error message, if any
  String? get errorMessage => _errorMessage;

  /// Initialize the provider by loading journey levels and user data
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load journey levels from JSON
      await _loadJourneyLevels();

      // Load user stats
      await _loadUserStats();

      // Calculate current level and progress
      _calculateCurrentLevel();

      // Preload pattern names for all levels
      await _preloadPatternNames();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error initializing journey: $e';
      notifyListeners();
    }
  }

  /// Preload pattern names for all levels to avoid loading them on-demand
  Future<void> _preloadPatternNames() async {
    final List<String> allSlugs = [];

    // Collect all slugs from all levels
    for (final level in _allLevels) {
      allSlugs.addAll(level.patternSlugs);
    }

    // Remove duplicates
    final uniqueSlugs = allSlugs.toSet().toList();

    // Fetch pattern names for all slugs
    for (final slug in uniqueSlugs) {
      try {
        final patternName = await getPatternName(slug);
        _patternNameCache[slug] = patternName;
      } catch (e) {
        debugPrint('Error loading pattern name for slug $slug: $e');
      }
    }
  }

  /// Get a breathing pattern name by slug
  Future<String> getPatternName(String slug) async {
    // Check cache first
    if (_patternNameCache.containsKey(slug)) {
      return _patternNameCache[slug]!;
    }

    try {
      // Query the database for the pattern name
      final response = await _supabase
          .from('breathing_patterns')
          .select('name')
          .eq('slug', slug)
          .maybeSingle();

      if (response != null && response['name'] != null) {
        final name = response['name'] as String;
        // Cache the result
        _patternNameCache[slug] = name;
        return name;
      }

      // Fallback: format the slug nicely if pattern not found
      final formattedName = _formatSlugAsName(slug);
      _patternNameCache[slug] = formattedName;
      return formattedName;
    } catch (e) {
      debugPrint('Error getting pattern name for slug $slug: $e');
      // Format the slug as a fallback
      final formattedName = _formatSlugAsName(slug);
      _patternNameCache[slug] = formattedName;
      return formattedName;
    }
  }

  /// Format a slug into a readable name (fallback if DB query fails)
  String _formatSlugAsName(String slug) {
    final words = slug.split('_');
    final formattedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    return formattedWords;
  }

  /// Load journey levels from the JSON file
  Future<void> _loadJourneyLevels() async {
    try {
      final String jsonData = await rootBundle
          .loadString('assets/data/breathing_journey_levels.json');
      _allLevels = parseJourneyLevels(jsonData);
      _allLevels
          .sort((a, b) => a.id.compareTo(b.id)); // Sort by ID just in case
    } catch (e) {
      throw Exception('Failed to load journey levels: $e');
    }
  }

  /// Load user stats from Supabase (BOLT scores and breathing sessions)
  Future<void> _loadUserStats() async {
    try {
      await Future.wait([
        _loadAverageBolt(),
        _loadWeeklyMinutes(),
      ]);
    } catch (e) {
      throw Exception('Failed to load user stats: $e');
    }
  }

  /// Load user's average BOLT score from the last 7 days
  Future<void> _loadAverageBolt() async {
    try {
      final DateTime sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('bolt_scores')
          .select('score_seconds')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        _averageBolt = 0.0;
        return;
      }

      int totalSeconds = 0;
      for (final score in data) {
        totalSeconds += (score['score_seconds'] as int);
      }

      _averageBolt = totalSeconds / data.length;
    } catch (e) {
      // If there's an error, default to 0
      _averageBolt = 0.0;
    }
  }

  /// Load user's total minutes of breathing practice in the last 7 days
  Future<void> _loadWeeklyMinutes() async {
    try {
      final DateTime sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('breathing_activity')
          .select('duration_seconds')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .eq('completed', true);

      final List<dynamic> data = response as List<dynamic>;

      if (data.isEmpty) {
        _weeklyMinutes = 0;
        return;
      }

      int totalSeconds = 0;
      for (final session in data) {
        totalSeconds += (session['duration_seconds'] as int);
      }

      _weeklyMinutes = totalSeconds ~/ 60;
    } catch (e) {
      // If there's an error, default to 0
      _weeklyMinutes = 0;
    }
  }

  /// Calculate current level based on BOLT score and weekly minutes
  void _calculateCurrentLevel() {
    if (_allLevels.isEmpty) return;

    // Start at level 1
    _currentLevelId = 1;

    // Find the highest level the user has unlocked
    for (final level in _allLevels) {
      if (_averageBolt >= level.boltMin &&
          _weeklyMinutes >= level.minutesWeek) {
        _currentLevelId = level.id;
      } else {
        break;
      }
    }

    // Calculate progress toward next level
    _calculateProgressPercent();
  }

  /// Calculate progress percentage toward the next level
  void _calculateProgressPercent() {
    if (_currentLevelId >= _allLevels.length) {
      // User has reached max level
      _progressPercent = 1.0;
      return;
    }

    final currentLevel =
        _allLevels.firstWhere((level) => level.id == _currentLevelId);
    final nextLevel =
        _allLevels.firstWhere((level) => level.id == _currentLevelId + 1);

    // Calculate BOLT progress
    final boltRange = nextLevel.boltMin - currentLevel.boltMin;
    final boltProgress = (_averageBolt - currentLevel.boltMin) / boltRange;
    final boltPercent = boltProgress.clamp(0.0, 1.0);

    // Calculate minutes progress
    final minutesRange = nextLevel.minutesWeek - currentLevel.minutesWeek;
    final minutesProgress =
        (_weeklyMinutes - currentLevel.minutesWeek) / minutesRange;
    final minutesPercent = minutesProgress.clamp(0.0, 1.0);

    // Overall progress is the average of BOLT and minutes progress
    _progressPercent = (boltPercent + minutesPercent) / 2;
  }

  /// Check if a specific level is unlocked
  bool isLevelUnlocked(int levelId) {
    return levelId <= _currentLevelId;
  }

  /// Check if user can unlock a specific level
  bool canUnlock(JourneyLevel level) {
    return _averageBolt >= level.boltMin && _weeklyMinutes >= level.minutesWeek;
  }

  /// Get requirements text for unlocking a level
  String getUnlockRequirementsText(JourneyLevel level) {
    final List<String> requirements = [];

    if (_averageBolt < level.boltMin) {
      requirements.add('BOLT ${level.boltMin}s');
    }

    if (_weeklyMinutes < level.minutesWeek) {
      requirements.add('${level.minutesWeek} min/semana');
    }

    if (requirements.isEmpty) {
      return 'Nivel desbloqueado';
    } else {
      return 'Requiere: ${requirements.join(' y ')}';
    }
  }

  /// Check progress after completing a breathing session
  /// Returns true if a new level was unlocked
  Future<bool> checkProgress() async {
    final int previousLevel = _currentLevelId;

    await _loadUserStats();
    _calculateCurrentLevel();

    notifyListeners();

    // Return true if a new level was unlocked
    return _currentLevelId > previousLevel;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// ─────────────────────────────────────────────────────── Data model
class Profile {
  final String id;
  final String? avatarUrl;
  final String? firstName;
  final String? lastName;
  final String? username;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Profile({
    required this.id,
    this.avatarUrl,
    this.firstName,
    this.lastName,
    this.username,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON ←→ Dart helpers (no build_runner needed)
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        avatarUrl: json['avatar_url'] as String?,
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        username: json['username'] as String?,
        dateOfBirth: json['date_of_birth'] == null
            ? null
            : DateTime.parse(json['date_of_birth'] as String),
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'avatar_url': avatarUrl,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Convenient immutable update
  Profile copyWith({
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? username,
    DateTime? dateOfBirth,
    DateTime? updatedAt,
  }) =>
      Profile(
        id: id,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        username: username ?? this.username,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// ─────────────────────────────────────────────────────── Provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<Profile>>(
        (ref) => ProfileNotifier());

class ProfileNotifier extends StateNotifier<AsyncValue<Profile>> {
  ProfileNotifier() : super(const AsyncLoading()) {
    _loadProfile();
  }

  final _client = Supabase.instance.client;

  // ─────────────────────────────────────────── Load
  Future<void> _loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single() as Map<String, dynamic>;

      // Create a new Profile instance with the data
      final profile = Profile.fromJson(data);

      // Update state with the new profile data
      state = AsyncData(profile);
    } catch (e, st) {
      debugPrint('Error loading profile: $e');
      debugPrint('Stack trace: $st');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ─────────────────────────────────────────── Avatar update
  Future<void> updateAvatar(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Update the database
      await _client.from('profiles').update({
        'avatar_url': url,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', user.id);

      // Update local state
      state = state.whenData((p) => p.copyWith(
            avatarUrl: url,
            updatedAt: DateTime.now(),
          ));
    } catch (e, st) {
      debugPrint('Error updating avatar: $e');
      debugPrint('Stack trace: $st');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ─────────────────────────────────────────── Generic update
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Update the database
      await _client.from('profiles').upsert(fields);

      // Merge the local copy
      state = state.whenData((p) => p.copyWith(
            firstName: fields['first_name'] as String? ?? p.firstName,
            lastName: fields['last_name'] as String? ?? p.lastName,
            username: fields['username'] as String? ?? p.username,
            dateOfBirth: fields['date_of_birth'] != null
                ? DateTime.parse(fields['date_of_birth'] as String)
                : p.dateOfBirth,
            updatedAt: DateTime.now(),
          ));
    } catch (e, st) {
      debugPrint('Error updating profile: $e');
      debugPrint('Stack trace: $st');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // ─────────────────────────────────────────── Refresh
  Future<void> refresh() => _loadProfile();
}

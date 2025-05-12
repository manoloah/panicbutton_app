import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

/// ───────────────────────── Data model
class Profile {
  final String id;
  final String? avatarUrl; // Signed URL for Image.network
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

  /// Immutable update helper
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

/// ───────────────────────── Provider
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<Profile>>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<AsyncValue<Profile>> {
  ProfileNotifier() : super(const AsyncLoading()) {
    _loadProfile();
  }

  final _client = Supabase.instance.client;

  /// Loads the profile and generates a signed URL for the avatar
  Future<void> _loadProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        // Set empty state when no user is authenticated instead of throwing an exception
        state = const AsyncData(Profile(id: ''));
        return;
      }

      final data =
          await _client.from('profiles').select().eq('id', user.id).single();

      String? raw = data['avatar_url'] as String?;
      String? signedAvatar;

      if (raw != null && raw.isNotEmpty) {
        String path;
        if (raw.startsWith('http')) {
          final uri = Uri.parse(raw);
          final seg = uri.pathSegments;
          final pubIdx = seg.indexOf('public');
          if (pubIdx >= 0 && seg.length > pubIdx + 2) {
            // Skip 'public' and bucket name
            path = seg.sublist(pubIdx + 2).join('/');
          } else {
            path = raw;
          }
        } else {
          path = raw;
        }
        signedAvatar = await SupabaseService.getSignedAvatarUrl(path);
      }

      state = AsyncData(
        Profile(
          id: data['id'] as String,
          avatarUrl: signedAvatar,
          firstName: data['first_name'] as String?,
          lastName: data['last_name'] as String?,
          username: data['username'] as String?,
          dateOfBirth: data['date_of_birth'] == null
              ? null
              : DateTime.parse(data['date_of_birth'] as String),
          createdAt: data['created_at'] == null
              ? null
              : DateTime.parse(data['created_at'] as String),
          updatedAt: data['updated_at'] == null
              ? null
              : DateTime.parse(data['updated_at'] as String),
        ),
      );
    } catch (e, st) {
      debugPrint('Error loading profile: $e');
      // Don't rethrow if it's a "not found" error which can happen during logout
      if (e is StorageException && e.statusCode == 404) {
        state = const AsyncData(Profile(id: ''));
      } else {
        state = AsyncError(e, st);
        rethrow;
      }
    }
  }

  /// Updates avatar path in DB then refreshes signed URL
  Future<void> updateAvatar(String filePath) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('profiles').update({
        'avatar_url': filePath,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      final signed = await SupabaseService.getSignedAvatarUrl(filePath);
      state = state.whenData(
        (p) => p.copyWith(
          avatarUrl: signed,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      debugPrint('Error updating avatar: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Generic profile update
  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      await _client.from('profiles').upsert(fields);
      state = state.whenData(
        (p) => p.copyWith(
          firstName: fields['first_name'] as String? ?? p.firstName,
          lastName: fields['last_name'] as String? ?? p.lastName,
          username: fields['username'] as String? ?? p.username,
          dateOfBirth: fields['date_of_birth'] != null
              ? DateTime.parse(fields['date_of_birth'] as String)
              : p.dateOfBirth,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e, st) {
      debugPrint('Error updating profile: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Expose refresh for UI
  Future<void> refresh() => _loadProfile();
}

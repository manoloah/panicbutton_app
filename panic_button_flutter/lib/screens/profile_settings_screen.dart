import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/profile_provider.dart';
import '../services/supabase_service.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  DateTime? _dob;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final profile = ref.read(profileProvider);
    if (profile.hasValue) {
      final p = profile.value!;
      _firstNameCtrl.text = p.firstName ?? '';
      _lastNameCtrl.text = p.lastName ?? '';
      _usernameCtrl.text = p.username ?? '';
      _dob = p.dateOfBirth;
      _dobCtrl.text = _formatDate(_dob);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final url = await SupabaseService.uploadAvatar(bytes);

      await ref.read(profileProvider.notifier).updateProfile({
        'id': userId,
        'avatar_url': url,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar actualizado')),
        );
      }
    } catch (_) {
      if (mounted) context.go('/auth');
    }
  }

  Future<void> _handleSignOut() async {
    await SupabaseService().signOut();
    if (mounted) context.go('/auth');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _dobCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy‑MM‑dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profile.avatarUrl != null
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        child: profile.avatarUrl == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // First name
                TextFormField(
                  controller: _firstNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),

                // Last name
                TextFormField(
                  controller: _lastNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Apellido',
                    helperText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    helperText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),

                // Date of birth
                TextFormField(
                  controller: _dobCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    helperText: 'Opcional',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (_) => null,
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (userId == null) {
                      if (mounted) context.go('/auth');
                      return;
                    }

                    await ref.read(profileProvider.notifier).updateProfile({
                      'id': userId,
                      'first_name': _firstNameCtrl.text.trim(),
                      'last_name': _lastNameCtrl.text.trim(),
                      'username': _usernameCtrl.text.trim(),
                      'date_of_birth': _dob?.toIso8601String(),
                      'updated_at': DateTime.now().toIso8601String(),
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perfil actualizado')),
                      );
                    }
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

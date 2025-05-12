import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;

import '../providers/profile_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/delayed_loading_animation.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  // -------------------------- Controllers & form state
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  DateTime? _dob;

  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Refresh profile data on load
    ref.read(profileProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  // -------------------------- Image processing
  Future<Uint8List?> _processImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final size = image.width < image.height ? image.width : image.height;
      final left = (image.width - size) ~/ 2;
      final top = (image.height - size) ~/ 2;

      final cropped =
          img.copyCrop(image, x: left, y: top, width: size, height: size);
      final resized = img.copyResize(cropped,
          width: 400, height: 400, interpolation: img.Interpolation.linear);

      return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  // -------------------------- Pick & upload avatar
  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;

      final processed = await _processImage(picked);
      if (processed == null) throw Exception('Error al procesar la imagen');

      // Upload and save only the file path
      final filePath = await SupabaseService.uploadAvatar(processed);
      debugPrint('Avatar stored at: $filePath');

      // Refresh provider to get a fresh signed URL
      await ref.read(profileProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Avatar actualizado')));
      }
    } catch (e, st) {
      debugPrint('Error picking image: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------- Date picker & formatter
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
        _hasUnsavedChanges = true;
      });
    }
  }

  // Formats date as 'yyyy-MM-dd' or empty string if null
  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // -------------------------- Confirmation dialog
  Future<void> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cambios'),
        content:
            const Text('¿Estás seguro de que deseas actualizar tu perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveProfile();
    }
  }

  // -------------------------- Save profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
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
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------- Sign-out
  Future<void> _handleSignOut() async {
    await SupabaseService().signOut();
    if (mounted) context.go('/auth');
  }

  // -------------------------- Build UI
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    // Sync form fields when profile changes
    profileAsync.whenData((profile) {
      if (!_hasUnsavedChanges) {
        if (_firstNameCtrl.text != profile.firstName) {
          _firstNameCtrl.text = profile.firstName ?? '';
        }
        if (_lastNameCtrl.text != profile.lastName) {
          _lastNameCtrl.text = profile.lastName ?? '';
        }
        if (_usernameCtrl.text != profile.username) {
          _usernameCtrl.text = profile.username ?? '';
        }
        if (_dob != profile.dateOfBirth) {
          _dob = profile.dateOfBirth;
          _dobCtrl.text = _formatDate(_dob);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            // Get screen width
            final screenWidth = MediaQuery.of(context).size.width;

            // Use different font sizes or text based on available width
            if (screenWidth < 360) {
              return const Text('Perfil', overflow: TextOverflow.visible);
            } else {
              return const Text('Configuración de Perfil',
                  overflow: TextOverflow.visible);
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleSignOut),
        ],
      ),
      body: profileAsync.when(
        loading: () => const SafeArea(
          child: DelayedLoadingAnimation(
            loadingText: 'Cargando tu perfil...',
            showQuote: true,
            delayMilliseconds: 500,
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar display & picker
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: profile.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profile.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.person, size: 50),
                                ),
                              )
                            : const Icon(Icons.person, size: 50),
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
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white),
                            onPressed: _isLoading ? null : _pickImage,
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  onChanged: (_) => setState(() => _hasUnsavedChanges = true),
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
                  onChanged: (_) => setState(() => _hasUnsavedChanges = true),
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
                  onChanged: (_) => setState(() => _hasUnsavedChanges = true),
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
                ),
                const SizedBox(height: 24),

                // Save button invokes confirmation dialog
                ElevatedButton(
                  onPressed: _isLoading || !_hasUnsavedChanges
                      ? null
                      : _showConfirmationDialog,
                  style: _isLoading || !_hasUnsavedChanges
                      ? null
                      : ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          elevation: 4,
                          shadowColor: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withAlpha((0.5 * 255).toInt()),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.4 * 255).toInt()),
                            width: 1.5,
                          ),
                        ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

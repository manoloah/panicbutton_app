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
  bool _isLoading = false;

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

  Future<Uint8List?> _processImage(XFile file) async {
    try {
      // Read the file
      final bytes = await file.readAsBytes();
      
      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Get the minimum dimension for square cropping
      final size = image.width < image.height ? image.width : image.height;
      
      // Calculate crop dimensions to make it square from the center
      final left = (image.width - size) ~/ 2;
      final top = (image.height - size) ~/ 2;
      
      // Crop and resize
      final cropped = img.copyCrop(
        image,
        x: left,
        y: top,
        width: size,
        height: size,
      );
      
      // Resize to 400x400
      final resized = img.copyResize(
        cropped,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.linear,
      );
      
      // Encode as JPEG
      return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      // Pick image
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (picked == null) {
        debugPrint('No image selected');
        return;
      }

      debugPrint('Image picked: ${picked.path}');

      // Process image
      final processedImageBytes = await _processImage(picked);
      if (processedImageBytes == null) {
        throw Exception('Error al procesar la imagen');
      }

      debugPrint('Image processed successfully. Size: ${processedImageBytes.length} bytes');

      // Upload to Supabase and get signed URL
      final signedUrl = await SupabaseService.uploadAvatar(processedImageBytes);
      debugPrint('Image uploaded successfully. Signed URL: $signedUrl');

      // No need to update profile here as it's done in SupabaseService.uploadAvatar

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar actualizado')),
        );
        // Refresh profile to get the new avatar URL
        ref.read(profileProvider.notifier).refresh();
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _pickImage: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(profileProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
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
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Error loading avatar: $error');
                                    return const Icon(Icons.person, size: 50);
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
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
                                : const Icon(Icons.camera_alt, color: Colors.white),
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
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

                // Save button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          setState(() => _isLoading = true);
                          try {
                            final userId =
                                Supabase.instance.client.auth.currentUser?.id;
                            if (userId == null) {
                              if (mounted) context.go('/auth');
                              return;
                            }

                            await ref
                                .read(profileProvider.notifier)
                                .updateProfile({
                              'id': userId,
                              'first_name': _firstNameCtrl.text.trim(),
                              'last_name': _lastNameCtrl.text.trim(),
                              'username': _usernameCtrl.text.trim(),
                              'date_of_birth': _dob?.toIso8601String(),
                              'updated_at': DateTime.now().toIso8601String(),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Perfil actualizado')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Error: ${e.toString()}')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
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

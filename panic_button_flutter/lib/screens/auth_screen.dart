// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:panic_button_flutter/config/env_config.dart';
import 'package:hcaptcha_flutter/hcaptcha_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true;
  String? _errorMessage;
  bool _configError = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Check if Supabase is properly configured
    _checkSupabaseConfig();
  }

  void _checkSupabaseConfig() {
    if (EnvConfig.supabaseUrl.isEmpty ||
        EnvConfig.supabaseAnonKey.isEmpty ||
        EnvConfig.supabaseUrl == "https://xyzcompany.supabase.co") {
      setState(() {
        _configError = true;
        _errorMessage =
            'Configuración de Supabase incorrecta. Verifica tus credenciales.';
      });
      if (kDebugMode) {
        debugPrint('⚠️ Supabase configuration error:');
        debugPrint('URL: ${EnvConfig.supabaseUrl}');
        debugPrint(
            'Anon Key: ${EnvConfig.supabaseAnonKey.isNotEmpty ? "Present (length: ${EnvConfig.supabaseAnonKey.length})" : "Empty"}');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (_isDisposed) return;

    setState(() => _errorMessage = message);

    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onError)),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getReadableError(String error) {
    if (_configError) {
      return 'Error de configuración. Contacte al soporte.';
    }

    if (error.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('User already registered')) {
      return 'Este email ya está registrado';
    } else if (error.contains('Invalid email')) {
      return 'Email inválido';
    } else if (error.contains('Password should be at least 6 characters')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('socket') ||
        error.contains('network') ||
        error.contains('connection') ||
        error.contains('timeout')) {
      return 'Error de conexión. Revisa tu conexión a internet.';
    } else if (error.contains('JWT') || error.contains('token')) {
      return 'Error de autenticación. Contacte al soporte.';
    }

    if (kDebugMode) {
      debugPrint('Unhandled auth error: $error');
    }

    return 'Ha ocurrido un error. Por favor intenta de nuevo.';
  }

  Future<String?> _getCaptchaToken() async {
    if (EnvConfig.hcaptchaSiteKey.isEmpty) return null;

    String? token;
    final completer = Completer<String?>();
    HCaptchaFlutter.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'success' && call.arguments != null) {
        final res = call.arguments as Map<dynamic, dynamic>;
        token = res['token'] as String?;
        completer.complete(token);
      } else if (call.method == 'error') {
        completer.complete(null);
      }
    });
    await HCaptchaFlutter.show({
      'siteKey': EnvConfig.hcaptchaSiteKey,
      'language': 'es',
    });
    return completer.future;
  }

  Future<void> _handleSubmit() async {
    if (_configError) {
      _showError('Error de configuración. Contacte al soporte.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        // Add debug info
        if (kDebugMode) {
          debugPrint(
              'Attempting login with email: ${_emailController.text.trim()}');
          debugPrint('Using Supabase URL: ${EnvConfig.supabaseUrl}');
        }

        final captchaToken = await _getCaptchaToken();
        if (captchaToken == null) {
          _showError('Por favor completa el captcha');
          return;
        }

        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          captchaToken: captchaToken,
        );

        if (response.user != null && !_isDisposed) {
          if (kDebugMode) {
            debugPrint('Login successful for user: ${response.user!.id}');
          }

          // Short delay to allow auth state to propagate
          await Future.delayed(const Duration(milliseconds: 300));

          // Check if widget is still mounted before accessing context
          if (!_isDisposed && mounted) {
            context.go('/');
          }
        } else if (!_isDisposed) {
          if (kDebugMode) {
            debugPrint('Login failed: No user returned');
          }
          _showError('No se pudo iniciar sesión');
        }
      } else {
        if (kDebugMode) {
          debugPrint(
              'Attempting signup with email: ${_emailController.text.trim()}');
        }

        final captchaToken = await _getCaptchaToken();
        if (captchaToken == null) {
          _showError('Por favor completa el captcha');
          return;
        }

        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          captchaToken: captchaToken,
        );

        if (response.user != null && !_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cuenta creada exitosamente. Por favor verifica tu email.'),
            ),
          );
          if (!_isDisposed) {
            setState(() => _isLogin = true);
          }
        } else if (!_isDisposed) {
          _showError('No se pudo crear la cuenta');
        }
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('Auth exception: ${e.message}');
      }
      if (!_isDisposed) {
        _showError(_getReadableError(e.message));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error: $e');
      }
      if (!_isDisposed) {
        _showError(_getReadableError(e.toString()));
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Tu botón de calma',
                  style: textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                Text(
                  _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                  style: textTheme.headlineMedium,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.error.withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _configError || _isLoading ? null : _handleSubmit,
                  style: (_configError || _isLoading)
                      ? null
                      : ElevatedButton.styleFrom(
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          elevation: 4,
                          shadowColor: cs.shadow.withAlpha((0.5 * 255).toInt()),
                          side: BorderSide(
                            color: cs.primary.withAlpha((0.4 * 255).toInt()),
                            width: 1.5,
                          ),
                        ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _configError || _isLoading
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? '¿No tienes una cuenta? Regístrate'
                        : '¿Ya tienes una cuenta? Inicia sesión',
                  ),
                ),
                if (_configError && kDebugMode) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Modo desarrollador: Error de configuración Supabase',
                    style:
                        TextStyle(color: cs.error, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'URL: ${EnvConfig.supabaseUrl}\nAnon Key: ${EnvConfig.supabaseAnonKey.substring(0, math.min(10, EnvConfig.supabaseAnonKey.length))}...',
                    style: TextStyle(color: cs.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ejecuta el script debug_run.sh con credenciales válidas.',
                    style: TextStyle(color: cs.error, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

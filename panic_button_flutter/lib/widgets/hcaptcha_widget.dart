import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panic_button_flutter/config/env_config.dart';
import 'dart:async';

class HCaptchaWidget extends StatefulWidget {
  final Function(String) onTokenReceived;
  final Function()? onError;

  const HCaptchaWidget({
    super.key,
    required this.onTokenReceived,
    this.onError,
  });

  @override
  State<HCaptchaWidget> createState() => _HCaptchaWidgetState();
}

class _HCaptchaWidgetState extends State<HCaptchaWidget> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initHCaptcha();
  }

  void _initHCaptcha() {
    final siteKey = EnvConfig.hcaptchaSiteKey;

    if (siteKey.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'hCaptcha site key not configured';
      });
      return;
    }

    // For now, we'll simulate the hCaptcha flow for web development
    if (kIsWeb) {
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Simulate successful hCaptcha completion for development
          Timer(const Duration(seconds: 1), () {
            if (mounted) {
              widget.onTokenReceived(
                  'dev-hcaptcha-token-${DateTime.now().millisecondsSinceEpoch}');
            }
          });
        }
      });
    } else {
      // For mobile platforms
      setState(() {
        _isLoading = false;
        _errorMessage = 'hCaptcha not implemented for mobile yet';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteKey = EnvConfig.hcaptchaSiteKey;

    if (siteKey.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade300),
          color: Colors.red.shade50,
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'hCaptcha Configuration Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please set HCAPTCHA_SITEKEY in your .env file',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
          color: Colors.orange.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initHCaptcha();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.security, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  '🔒 Verificación de Seguridad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Por favor completa la verificación para continuar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (kIsWeb) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 48, color: Colors.green),
                        const SizedBox(height: 8),
                        const Text(
                          'hCaptcha Simulation (Development)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Site Key: ${siteKey.substring(0, 20)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Auto-completing for development...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.shade50,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_android, color: Colors.blue, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Mobile hCaptcha',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Coming soon for mobile platforms',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando verificación...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

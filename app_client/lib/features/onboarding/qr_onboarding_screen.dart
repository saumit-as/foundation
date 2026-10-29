import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/config/credentials_store.dart';
import '../../core/providers.dart';

class QrOnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onConnected;

  const QrOnboardingScreen({super.key, required this.onConnected});

  @override
  ConsumerState<QrOnboardingScreen> createState() => _QrOnboardingScreenState();
}

class _QrOnboardingScreenState extends ConsumerState<QrOnboardingScreen> {
  final _jsonController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  bool _showScanner = false;

  @override
  void initState() {
    super.initState();
    // Default to camera scanner on Android/iOS if not in desktop/test
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _showScanner = true;
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _processPayload(String raw) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final creds = DeviceCredentials.fromQrString(raw);
      if (!creds.isValid) {
        throw const FormatException('Invalid device credentials bundle.');
      }

      final store = ref.read(credentialsStoreProvider);
      await store.saveCredentials(creds);

      // Trigger initial delta sync
      try {
        final flusher = ref.read(outboxFlusherProvider);
        await flusher.syncDelta();
      } catch (syncErr) {
        debugPrint('Initial delta sync notice: $syncErr');
      }

      if (mounted) {
        widget.onConnected();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.security_rounded,
                    size: 56,
                    color: Color(0xFF818CF8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pair with Memoria Server',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scan the terminal QR code or paste your Zero-Trust device pairing JSON bundle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_showScanner && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MobileScanner(
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          for (final b in barcodes) {
                            if (b.rawValue != null) {
                              _processPayload(b.rawValue!);
                              break;
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _showScanner = false),
                      child: const Text('Switch to Manual JSON Paste'),
                    ),
                  ] else ...[
                    TextField(
                      controller: _jsonController,
                      maxLines: 5,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFFE2E8F0),
                      ),
                      decoration: InputDecoration(
                        hintText: '{\n  "v": 1,\n  "api_base_url": "...",\n  "bearer_key": "..."\n}',
                        hintStyle: const TextStyle(color: Color(0xFF475569)),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF818CF8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isConnecting
                          ? null
                          : () => _processPayload(_jsonController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isConnecting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Connect Device',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF450A0A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFB91C1C)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

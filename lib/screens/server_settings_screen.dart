import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../core/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';
import '../widgets/app_toast.dart';

/// Lets the user point the app at their PC's backend, e.g.
/// `http://192.168.1.5:5151` (or with `/api`). Also verifies connectivity by
/// hitting the public-key endpoint.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _controller;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final base = _normalize(_controller.text);
      final response = await http
          .get(Uri.parse('$base/api/security/public-key'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final ok = body['success'] == true && body['data'] != null;
        setState(() {
          _testOk = ok;
          _testResult = ok
              ? '✓ Server reachable — backend keys exchanged successfully.'
              : 'Server responded but returned an unexpected payload.';
        });
      } else {
        setState(() {
          _testOk = false;
          _testResult = 'Server responded with HTTP ${response.statusCode}.';
        });
      }
    } catch (_) {
      setState(() {
        _testOk = false;
        _testResult =
            'Could not reach the server. Check that the backend is running and '
            'this device is on the same network, and the firewall allows port '
            '5151 inbound.';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  String _normalize(String raw) {
    var s = raw.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    if (s.endsWith('/api')) s = s.substring(0, s.length - 4);
    return s;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await AppConfig.setBaseUrl(_controller.text);
      if (!mounted) return;
      showAppToast(context, 'Server address saved.',
          type: ToastType.success);
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(title: const Text('Server Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blue50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.blue700),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter the address of the PC running the backend. On your '
                      'phone this must be the PC\'s LAN IP (e.g. '
                      'http://192.168.137.1:5151) — not "localhost". The phone '
                      'and PC must be on the same Wi-Fi or the PC\'s hotspot.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.blue700,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppInput(
              label: 'Backend base URL',
              hint: 'http://192.168.1.5:5151',
              icon: Icons.dns_outlined,
              controller: _controller,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${AppConfig.baseUrl}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
            const SizedBox(height: 20),
            if (_testResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testOk ? AppColors.green50 : AppColors.red50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _testOk ? AppColors.green200 : AppColors.red200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _testOk ? Icons.check_circle : Icons.error_outline,
                      size: 18,
                      color: _testOk ? AppColors.green700 : AppColors.red600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _testOk
                              ? AppColors.green800
                              : AppColors.red700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppButton(
              label: 'Test connection',
              variant: ButtonVariant.outline,
              isLoading: _isTesting,
              fullWidth: true,
              onPressed: _testConnection,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Save',
              isLoading: _isSaving,
              fullWidth: true,
              onPressed: _save,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await AppConfig.reset();
                _controller.text = AppConfig.baseUrl;
                setState(() => _testResult = null);
              },
              child: const Text(
                'Reset to default',
                style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

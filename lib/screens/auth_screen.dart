import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Введите номер телефона');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final authService = context.read<AuthService>();
    authService.sendOtp(
      phone,
      (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _loading = false;
        });
      },
      (error) {
        setState(() {
          _error = error;
          _loading = false;
        });
      },
    );
  }

  void _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Введите 6-значный код');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final authService = context.read<AuthService>();
    final success = await authService.verifyOtp(_verificationId!, code);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _error = 'Неверный код';
        _loading = false;
      });
    }
    // If success, auth state will handle navigation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Должок',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Учёт долгов между друзьями',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),

              if (!_codeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 999 123 45 67',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Получить код', style: TextStyle(fontSize: 16)),
                ),
              ] else ...[
                Text(
                  'Код отправлен на ${_phoneController.text}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Код из SMS',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Войти', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _codeSent = false;
                      _otpController.clear();
                      _error = null;
                    });
                  },
                  child: const Text('Изменить номер'),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

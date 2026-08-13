import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(), 
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  CupertinoIcons.creditcard_fill,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Должок',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Учёт долгов между друзьями',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
              ),
              const SizedBox(height: 48),

              // Google Sign-In Button - iPhone Style
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // Dismiss keyboard before sign-in
                      FocusManager.instance.primaryFocus?.unfocus();
                      await Future.delayed(const Duration(milliseconds: 50));
                      
                      final authService = context.read<AuthService>();
                      await authService.signInWithGoogle();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) => 
                                Icon(Icons.g_mobiledata, size: 24, color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Войти через Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'После входа мы получим ваш номер телефона и данные из Google аккаунта',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

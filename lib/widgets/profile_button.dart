import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';

class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showProfileSheet(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.person_circle_outline,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: ListView(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (user?.displayName ?? 'U').isNotEmpty
                              ? (user?.displayName ?? 'U')[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3A3A3C)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1C1C1E)
                                  : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?.displayName ?? 'Пользователь',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline,
                          title: 'Профиль',
                          isDark: isDark,
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          icon: Icons.notifications_outlined,
                          title: 'Уведомления',
                          isDark: isDark,
                          onTap: () => Navigator.pop(ctx),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          icon: Icons.security_outlined,
                          title: 'Безопасность',
                          isDark: isDark,
                          onTap: () => Navigator.pop(ctx),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Помощь',
                          isDark: isDark,
                          onTap: () => Navigator.pop(ctx),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Выйти',
                          isDark: isDark,
                          isDestructive: true,
                          onTap: () async {
                            Navigator.pop(ctx);
                            await authService.signOut();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isDark,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isDestructive
                      ? const Color(0xFFFF3B30)
                      : (isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF8E8E93)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? const Color(0xFFFF3B30)
                          : (isDark
                                ? Colors.white
                                : const Color(0xFF1C1C1E)),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

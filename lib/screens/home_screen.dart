import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'active_debts_screen.dart';
import 'history_screen.dart';
import 'create_debt_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ActiveDebtsScreen(),
      const HistoryScreen(),
      const ContactsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Должок'),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 1)
            IconButton(
              icon: const Icon(CupertinoIcons.person_circle),
              onPressed: () => _showProfileSheet(context),
            ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(CupertinoIcons.doc_text),
            selectedIcon: Icon(CupertinoIcons.doc_text_fill),
            label: 'Активные',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.clock),
            selectedIcon: Icon(CupertinoIcons.clock_fill),
            label: 'История',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.person_2),
            selectedIcon: Icon(CupertinoIcons.person_2_fill),
            label: 'Контакты',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateDebtScreen()),
                );
              },
              icon: const Icon(CupertinoIcons.plus),
              label: const Text('Новый долг'),
            )
          : null,
    );
  }

  void _showProfileSheet(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue[100],
                child: Text(
                  (user?.displayName ?? 'U').isNotEmpty
                      ? (user?.displayName ?? 'U')[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ?? 'Пользователь',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.phoneNumber ?? '',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(CupertinoIcons.square_arrow_left,
                    color: Colors.red),
                title: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Выход'),
                      content: const Text('Выйти из аккаунта?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && mounted) {
                    await authService.signOut();
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_bottom_nav.dart';
import '../widgets/profile_button.dart';
import '../widgets/floating_action_button_group.dart';
import 'active_debts_screen.dart';
import 'history_screen.dart';
import 'create_debt_screen.dart';
import 'contacts_screen.dart';
import '../models/debt_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screens = [
      const ActiveDebtsScreen(),
      const HistoryScreen(),
      const ContactsScreen(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Должок',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          actions: [
            if (_currentIndex == 0 || _currentIndex == 1)
              const ProfileButton(),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: screens,
        ),
        bottomNavigationBar: GlassBottomNav(
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
            );
          },
          isDark: isDark,
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButtonGroup(
                onIOweTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateDebtScreen(
                      debtType: DebtType.iOwe,
                    ),
                  ),
                ),
                onOwedToMeTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateDebtScreen(
                      debtType: DebtType.owedToMe,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

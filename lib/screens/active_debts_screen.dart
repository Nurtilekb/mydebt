import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../models/debt_model.dart';
import 'debt_detail_screen.dart';

class ActiveDebtsScreen extends StatefulWidget {
  const ActiveDebtsScreen({super.key});

  @override
  State<ActiveDebtsScreen> createState() => _ActiveDebtsScreenState();
}

class _ActiveDebtsScreenState extends State<ActiveDebtsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    final phone = user.phoneNumber ?? '';
    final debtService = context.read<DebtService>();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2C2C2E)
                : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF8E8E93)
                : const Color(0xFF8E8E93),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            tabs: const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Мне должны',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Я должен',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: "Мне должны" — I'm creator, I lent money, others owe me
              _DebtList(
                stream: debtService.getMyCreatedDebts(phone),
                myRole: 'creator',
                emptyMessage: 'Нет долгов, которые вам должны',
                confirmLabel: 'Я получил, подтверждаю',
                isCreditor: true,
              ),
              // Tab 2: "Я должен" — I'm participant, someone lent to me, I owe
              _DebtList(
                stream: debtService.getParticipantDebts(phone),
                myRole: 'participant',
                emptyMessage: 'Нет долгов, которые вы должны',
                confirmLabel: 'Я оплатил, подтверждаю',
                isCreditor: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DebtList extends StatelessWidget {
  final Stream<List<Debt>> stream;
  final String myRole;
  final String emptyMessage;
  final String confirmLabel;
  final bool isCreditor;

  const _DebtList({
    required this.stream,
    required this.myRole,
    required this.emptyMessage,
    required this.confirmLabel,
    required this.isCreditor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<List<Debt>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final debts = snapshot.data ?? [];

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCreditor
                        ? CupertinoIcons.arrow_down_circle
                        : CupertinoIcons.arrow_up_circle,
                    size: 50,
                    color: isDark
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              return _DebtCard(
                debt: debt,
                myRole: myRole,
                confirmLabel: confirmLabel,
                isCreditor: isCreditor,
              );
            },
          ),
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String myRole;
  final String confirmLabel;
  final bool isCreditor;

  const _DebtCard({
    required this.debt,
    required this.myRole,
    required this.confirmLabel,
    required this.isCreditor,
  });

  Color _getStatusColor() {
    if (debt.status == DebtStatus.pending)
      return const Color(0xFFFF9500); // iOS Orange
    if (debt.status == DebtStatus.confirmedByCreator ||
        debt.status == DebtStatus.confirmedByParticipant)
      return const Color(0xFF007AFF); // iOS Blue
    return const Color(0xFF8E8E93); // iOS Gray
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myConfirmed = debt.confirmations[myRole] == true;

    // Determine the other person's name based on my role
    final otherName = myRole == 'creator'
        ? (debt.participantName ?? debt.participantPhone)
        : debt.creatorName;

    // Color coding: green for money I'll get, red for money I owe
    final amountColor = isCreditor
        ? const Color(0xFF34C759) // iOS Green
        : const Color(0xFFFF3B30); // iOS Red

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebtDetailScreen(debtId: debt.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isCreditor
                          ? CupertinoIcons.arrow_down_left
                          : CupertinoIcons.arrow_up_right,
                      color: _getStatusColor(),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName ?? 'Неизвестно',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF000000),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCreditor ? 'Должен вам' : 'Вы должны',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${debt.amount.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        letterSpacing: -0.5,
                        color: amountColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (debt.description != null && debt.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    debt.description!,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFEBEBF5)
                          : const Color(0xFF3A3A3C),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(debt.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                  const Spacer(),
                  if (myConfirmed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled,
                            size: 14,
                            color: Color(0xFF34C759),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Подтверждено',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF34C759),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        debt.statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Confirm button for this debt
              if (!debt.isClosed && !myConfirmed) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF34C759),
                        const Color(0xFF30B753),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34C759).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _confirmDebt(context),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.check_mark,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              confirmLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    }
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _confirmDebt(BuildContext context) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    await context.read<DebtService>().confirmDebt(debt.id, myRole);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(CupertinoIcons.check_mark_circled, color: Colors.white),
              SizedBox(width: 12),
              Text('Подтверждено'),
            ],
          ),
          backgroundColor: const Color(0xFF34C759),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

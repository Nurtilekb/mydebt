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
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мне должны'),
            Tab(text: 'Я должен'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
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
              ),
              // Tab 2: "Я должен" — I'm participant, someone lent to me, I owe
              _DebtList(
                stream: debtService.getParticipantDebts(phone),
                myRole: 'participant',
                emptyMessage: 'Нет долгов, которые вы должны',
                confirmLabel: 'Я оплатил, подтверждаю',
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

  const _DebtList({
    required this.stream,
    required this.myRole,
    required this.emptyMessage,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final debts = snapshot.data ?? [];

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.doc_text,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 17, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: debts.length,
          itemBuilder: (context, index) {
            final debt = debts[index];
            return _DebtCard(
              debt: debt,
              myRole: myRole,
              confirmLabel: confirmLabel,
            );
          },
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String myRole;
  final String confirmLabel;

  const _DebtCard({
    required this.debt,
    required this.myRole,
    required this.confirmLabel,
  });

  Color _getStatusColor() {
    if (debt.status == DebtStatus.pending) return Colors.orange;
    if (debt.status == DebtStatus.confirmedByCreator ||
        debt.status == DebtStatus.confirmedByParticipant)
      return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final myConfirmed = debt.confirmations[myRole] == true;

    // Determine the other person's name based on my role
    final otherName = myRole == 'creator'
        ? (debt.participantName ?? debt.participantPhone)
        : debt.creatorName;

    // Color coding: green for money I'll get, red for money I owe
    final isCreditor = myRole == 'creator';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DebtDetailScreen(debtId: debt.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCreditor
                          ? CupertinoIcons.arrow_down_left
                          : CupertinoIcons.arrow_up_right,
                      color: _getStatusColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          isCreditor ? 'Должен вам' : 'Вы должны',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${debt.amount.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isCreditor ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
                ],
              ),
              if (debt.description != null &&
                  debt.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    debt.description!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(CupertinoIcons.clock,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(debt.createdAt),
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  if (myConfirmed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Вы подтвердили',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        debt.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              // Confirm button for this debt
              if (!debt.isClosed && !myConfirmed) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDebt(context),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      confirmLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _confirmDebt(BuildContext context) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    await context.read<DebtService>().confirmDebt(debt.id, myRole);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Подтверждено')),
      );
    }
  }
}

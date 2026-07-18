import 'package:flutter/material.dart';
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
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Debts where user is creator (others owe me)
              _DebtList(
                stream: debtService.getMyCreatedDebts(phone),
                role: 'creator',
                emptyMessage: 'Нет долгов, которые вам должны',
              ),
              // Debts where user is participant (I owe others)
              _DebtList(
                stream: debtService.getParticipantDebts(phone),
                role: 'participant',
                emptyMessage: 'Нет долгов, которые вы должны',
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
  final String role;
  final String emptyMessage;

  const _DebtList({
    required this.stream,
    required this.role,
    required this.emptyMessage,
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
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
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
            return _DebtCard(debt: debt, role: role);
          },
        );
      },
    );
  }
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String role;

  const _DebtCard({required this.debt, required this.role});

  Color _getStatusColor() {
    if (debt.status == DebtStatus.pending) return Colors.orange;
    if (debt.status == DebtStatus.confirmedByCreator ||
        debt.status == DebtStatus.confirmedByParticipant)
      return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final isCreator = user?.phoneNumber == debt.creatorPhone;
    final otherName = isCreator
        ? (debt.participantName ?? debt.participantPhone)
        : debt.creatorName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  CircleAvatar(
                    backgroundColor: _getStatusColor().withValues(alpha: 0.1),
                    child: Icon(
                      isCreator ? Icons.person_add : Icons.person,
                      color: _getStatusColor(),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isCreator ? 'Должен вам' : 'Вы должны',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${debt.amount.toStringAsFixed(0)} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isCreator ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (debt.description != null && debt.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  debt.description!,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(debt.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      debt.statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

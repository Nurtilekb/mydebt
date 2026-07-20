import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../models/debt_model.dart';

class DebtDetailScreen extends StatefulWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    final debtService = context.read<DebtService>();

    return StreamBuilder<Debt?>(
      stream: debtService.watchDebt(widget.debtId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final debt = snapshot.data;
        if (debt == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Долг')),
            body: const Center(child: Text('Долг не найден')),
          );
        }

        final isCreator = user.uid == debt.creatorUid;
        final otherName = isCreator
            ? (debt.participantName ?? debt.participantPhone)
            : debt.creatorName;
        final otherPhone =
            isCreator ? debt.participantPhone : debt.creatorPhone;
        final myRole = isCreator ? 'creator' : 'participant';
        final myConfirmed = debt.confirmations[myRole] == true;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Детали долга'),
            actions: [
              if (debt.isClosed)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(debt),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Card(
                  color: debt.isClosed
                      ? (debt.status == DebtStatus.closed
                          ? Colors.green[50]
                          : Colors.red[50])
                      : Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '${debt.amount.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: debt.isClosed
                                ? (debt.status == DebtStatus.closed
                                    ? Colors.green
                                    : Colors.red)
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(debt.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            debt.statusLabel,
                            style: TextStyle(
                              color: _getStatusColor(debt.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Participant info
                Text(
                  isCreator ? 'Кому вы должны' : 'Кто вам должен',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        otherName.isNotEmpty
                            ? otherName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(otherName),
                    subtitle: Text(otherPhone),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                if (debt.description != null &&
                    debt.description!.isNotEmpty) ...[
                  Text(
                    'Описание',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(debt.description!),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Confirmation status
                Text(
                  'Подтверждение',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          debt.confirmations['creator'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: debt.confirmations['creator'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(debt.creatorName),
                        subtitle: const Text('Создатель'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          debt.confirmations['participant'] == true
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: debt.confirmations['participant'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                        title: Text(
                          debt.participantName ?? debt.participantPhone,
                        ),
                        subtitle: const Text('Участник'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dates
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Создан'),
                        trailing: Text(_formatDate(debt.createdAt)),
                      ),
                      if (debt.closedAt != null)
                        ListTile(
                          leading: const Icon(Icons.check),
                          title: const Text('Закрыт'),
                          trailing: Text(_formatDate(debt.closedAt!)),
                        ),
                    ],
                  ),
                ),

                if (!debt.isClosed) ...[
                  const SizedBox(height: 32),

                  // Confirm / cancel buttons
                  if (myConfirmed)
                    Card(
                      color: Colors.green[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Вы подтвердили оплату. Ожидается подтверждение другой стороны.',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // "I paid the debt" confirm button
                        ElevatedButton(
                          onPressed: () => _confirmPaid(debt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Я оплатил долг',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Cancel / reject button
                        OutlinedButton(
                          onPressed: () => _rejectDebt(debt),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(DebtStatus status) {
    switch (status) {
      case DebtStatus.pending:
        return Colors.orange;
      case DebtStatus.confirmedByCreator:
      case DebtStatus.confirmedByParticipant:
        return Colors.blue;
      case DebtStatus.closed:
        return Colors.green;
      case DebtStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _confirmPaid(Debt debt) async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    final role =
        user.uid == debt.creatorUid ? 'creator' : 'participant';
    await context.read<DebtService>().confirmDebt(debt.id, role);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оплата подтверждена')),
      );
    }
  }

  void _rejectDebt(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить долг?'),
        content: const Text('Долг будет помечен как отклонённый'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<DebtService>().rejectDebt(debt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Долг отклонён')),
        );
      }
    }
  }

  void _confirmDelete(Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<DebtService>().deleteDebt(debt.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

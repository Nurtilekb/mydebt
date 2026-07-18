import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../models/debt_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterQuery = '';
  String _sortBy = 'date';

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    final phone = user.phoneNumber ?? '';
    final debtService = context.read<DebtService>();

    return Column(
      children: [
        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Поиск по описанию...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: (value) {
                  setState(() => _sortBy = value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'date', child: Text('По дате')),
                  const PopupMenuItem(value: 'amount', child: Text('По сумме')),
                ],
              ),
            ),
            onChanged: (value) {
              setState(() => _filterQuery = value);
            },
          ),
        ),

        // History list
        Expanded(
          child: StreamBuilder<List<Debt>>(
            stream: debtService.getArchivedDebts(phone),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var debts = snapshot.data ?? [];

              // Apply filter
              if (_filterQuery.isNotEmpty) {
                debts = debts.where((d) =>
                    (d.description ?? '').toLowerCase().contains(_filterQuery.toLowerCase()) ||
                    d.creatorName.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                    (d.participantName ?? '').toLowerCase().contains(_filterQuery.toLowerCase()))
                    .toList();
              }

              // Apply sort
              if (_sortBy == 'amount') {
                debts.sort((a, b) => b.amount.compareTo(a.amount));
              }

              if (debts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Нет завершённых долгов',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: debts.length,
                itemBuilder: (context, index) {
                  final debt = debts[index];
                  return _HistoryCard(debt: debt);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Debt debt;

  const _HistoryCard({required this.debt});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    final isCreator = user?.phoneNumber == debt.creatorPhone;
    final otherName = isCreator
        ? (debt.participantName ?? debt.participantPhone)
        : debt.creatorName;

    final isClosed = debt.status == DebtStatus.closed;
    final color = isClosed ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(
            isClosed ? Icons.check_circle : Icons.cancel,
            color: color,
          ),
        ),
        title: Text(otherName),
        subtitle: Text(
          '${isClosed ? 'Закрыт' : 'Отклонён'} · ${_formatDate(debt.closedAt ?? debt.createdAt)}',
        ),
        trailing: Text(
          '${debt.amount.toStringAsFixed(0)} ₽',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        onTap: () {
          _showDetails(context);
        },
        onLongPress: () {
          _confirmDelete(context);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Детали долга',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Сумма', value: '${debt.amount.toStringAsFixed(0)} ₽'),
            _DetailRow(label: 'Создатель', value: debt.creatorName),
            _DetailRow(label: 'Участник', value: debt.participantName ?? debt.participantPhone),
            if (debt.description != null && debt.description!.isNotEmpty)
              _DetailRow(label: 'Описание', value: debt.description!),
            _DetailRow(label: 'Создан', value: _formatDate(debt.createdAt)),
            _DetailRow(
              label: 'Закрыт',
              value: debt.closedAt != null ? _formatDate(debt.closedAt!) : '-',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<DebtService>().deleteDebt(debt.id);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

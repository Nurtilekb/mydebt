import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
        // Search and filter - iOS Style
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск...',
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(CupertinoIcons.sort_up_circle, size: 24),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'date', child: Text('По дате')),
                    const PopupMenuItem(
                      value: 'amount',
                      child: Text('По сумме'),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                setState(() => _filterQuery = value);
              },
            ),
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
                debts = debts
                    .where(
                      (d) =>
                          (d.description ?? '').toLowerCase().contains(
                            _filterQuery.toLowerCase(),
                          ) ||
                          d.creatorName.toLowerCase().contains(
                            _filterQuery.toLowerCase(),
                          ) ||
                          (d.participantName ?? '').toLowerCase().contains(
                            _filterQuery.toLowerCase(),
                          ),
                    )
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
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.time_solid,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет завершённых долгов',
                        style: TextStyle(fontSize: 17, color: Colors.grey[500]),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.read<AuthService>().currentUser;
    final isCreator = user?.phoneNumber == debt.creatorPhone;
    final otherName = isCreator
        ? (debt.participantName ?? debt.participantPhone)
        : debt.creatorName;

    final isClosed = debt.status == DebtStatus.closed;
    final statusColor = isClosed
        ? const Color(0xFF34C759) // iOS Green
        : const Color(0xFFFF3B30); // iOS Red

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetails(context),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isClosed
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.xmark_circle_fill,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherName ?? 'Неизвестно',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isClosed ? 'Закрыт' : 'Отклонён',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${debt.amount.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        letterSpacing: -0.5,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(debt.closedAt ?? debt.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      return '${difference.inDays} дн.';
    }
    return '${date.day}.${date.month.toString().padLeft(2, '0')}';
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Детали долга',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Сумма',
                      value: '${debt.amount.toStringAsFixed(0)} ₽',
                    ),
                    _DetailRow(label: 'Создатель', value: debt.creatorName),
                    _DetailRow(
                      label: 'Участник',
                      value: debt.participantName ?? debt.participantPhone,
                    ),
                    if (debt.description != null &&
                        debt.description!.isNotEmpty)
                      _DetailRow(label: 'Описание', value: debt.description!),
                    _DetailRow(
                      label: 'Создан',
                      value: _formatDate(debt.createdAt),
                    ),
                    _DetailRow(
                      label: 'Закрыт',
                      value: debt.closedAt != null
                          ? _formatDate(debt.closedAt!)
                          : '-',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          children: [
            Icon(
              CupertinoIcons.trash,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text('Удалить из истории?'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Это действие нельзя отменить',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              await context.read<DebtService>().deleteDebt(debt.id);
              if (context.mounted) Navigator.pop(context);
            },
            isDestructiveAction: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

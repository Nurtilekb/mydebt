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

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _filterQuery = '';
  String _sortBy = 'date';
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
        // Tabs for "Мне должны" and "Я должен"
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

        // History list with tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: "Мне должны" — I'm creator, I lent money, others owe me
              _HistoryList(
                stream: debtService.getMyCreatedDebts(phone),
                myRole: 'creator',
                emptyMessage: 'Нет завершённых долгов, которые вам должны',
                isCreditor: true,
                filterQuery: _filterQuery,
                sortBy: _sortBy,
                debtType: DebtType.owedToMe,
              ),
              // Tab 2: "Я должен" — I'm participant, someone lent to me, I owe
              _HistoryList(
                stream: debtService.getParticipantDebts(phone),
                myRole: 'participant',
                emptyMessage: 'Нет завершённых долгов, которые вы должны',
                isCreditor: false,
                filterQuery: _filterQuery,
                sortBy: _sortBy,
                debtType: DebtType.iOwe,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryList extends StatefulWidget {
  final Stream<List<Debt>> stream;
  final String myRole;
  final String emptyMessage;
  final bool isCreditor;
  final String filterQuery;
  final String sortBy;
  final DebtType debtType;

  const _HistoryList({
    required this.stream,
    required this.myRole,
    required this.emptyMessage,
    required this.isCreditor,
    required this.filterQuery,
    required this.sortBy,
    required this.debtType,
  });

  @override
  State<_HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<_HistoryList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Debt>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        var debts = snapshot.data ?? [];

        // Filter only closed debts
        debts = debts
            .where(
              (d) =>
                  d.debtType == widget.debtType &&
                  d.status == DebtStatus.closed,
            )
            .toList();

        // Apply filter
        if (widget.filterQuery.isNotEmpty) {
          debts = debts
              .where(
                (d) =>
                    (d.description ?? '').toLowerCase().contains(
                      widget.filterQuery.toLowerCase(),
                    ) ||
                    d.creatorName.toLowerCase().contains(
                      widget.filterQuery.toLowerCase(),
                    ) ||
                    (d.participantName ?? '').toLowerCase().contains(
                      widget.filterQuery.toLowerCase(),
                    ),
              )
              .toList();
        }

        // Apply sort
        if (widget.sortBy == 'amount') {
          debts.sort((a, b) => b.amount.compareTo(a.amount));
        }

        if (debts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2E)
                        : const Color(0xFFE5E5EA),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isCreditor
                        ? CupertinoIcons.arrow_down_circle
                        : CupertinoIcons.arrow_up_circle,
                    size: 50,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.emptyMessage,
                  style: TextStyle(
                    fontSize: 17,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF8E8E93),
                    fontWeight: FontWeight.w500,
                  ),
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
            return _HistoryCard(debt: debt, isCreditor: widget.isCreditor);
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Debt debt;
  final bool isCreditor;

  const _HistoryCard({required this.debt, required this.isCreditor});

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

    // Color coding: green for money I'll get, red for money I owe
    final amountColor = isCreditor
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
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isCreditor
                        ? CupertinoIcons.arrow_down_left
                        : CupertinoIcons.arrow_up_right,
                    color: amountColor,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: -0.3,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCreditor ? 'Должен вам' : 'Вы должны',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8E8E93),
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
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(debt.closedAt ?? debt.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF8E8E93),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                          color: isDark
                              ? const Color(0xFF3A3A3C)
                              : const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Детали долга',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF000000),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3A3A3C),
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
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }
}

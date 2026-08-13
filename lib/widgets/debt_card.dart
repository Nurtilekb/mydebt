import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/debt_model.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;
  final VoidCallback? onPayPress;
  final bool isDark;

  const DebtCard({
    super.key,
    required this.debt,
    required this.onTap,
    this.onPayPress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isIOwe = debt.type == DebtType.iOwe;
    final amountColor = isIOwe
        ? const Color(0xFFFF3B30)
        : Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        debt.contactName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: amountColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isIOwe ? 'Я должен' : 'Мне должны',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: amountColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${debt.amount.toStringAsFixed(2)} ₽',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (onPayPress != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              amountColor,
                              amountColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: amountColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: onPayPress,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Вернуть',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (debt.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    debt.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF8E8E93),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(debt.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF8E8E93)
                                : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                    if (debt.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: _isOverdue(debt.dueDate!)
                                ? const Color(0xFFFF3B30)
                                : (isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF8E8E93)),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isOverdue(debt.dueDate!)
                                ? 'Просрочено'
                                : 'До ${_formatDate(debt.dueDate!)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isOverdue(debt.dueDate!)
                                  ? const Color(0xFFFF3B30)
                                  : (isDark
                                      ? const Color(0xFF8E8E93)
                                      : const Color(0xFF8E8E93)),
                            ),
                          ),
                        ],
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
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  bool _isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }
}

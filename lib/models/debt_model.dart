import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtStatus {
  pending,
  confirmedByCreator,
  confirmedByParticipant,
  closed,
  rejected,
}

class Debt {
  final String id;
  final String creatorUid;
  final String creatorPhone;
  final String creatorName;
  final String participantPhone;
  final String? participantUid;
  final String? participantName;
  final double amount;
  final String? description;
  final DateTime createdAt;
  final DateTime? closedAt;
  final DebtStatus status;
  final Map<String, bool> confirmations;
  final bool archived;

  Debt({
    required this.id,
    required this.creatorUid,
    required this.creatorPhone,
    required this.creatorName,
    required this.participantPhone,
    this.participantUid,
    this.participantName,
    required this.amount,
    this.description,
    required this.createdAt,
    this.closedAt,
    this.status = DebtStatus.pending,
    this.confirmations = const {},
    this.archived = false,
  });

  bool get isClosed =>
      status == DebtStatus.closed || status == DebtStatus.rejected;

  String get statusLabel {
    switch (status) {
      case DebtStatus.pending:
        return 'Ожидает';
      case DebtStatus.confirmedByCreator:
        return 'Подтверждено создателем';
      case DebtStatus.confirmedByParticipant:
        return 'Подтверждено участником';
      case DebtStatus.closed:
        return 'Закрыт';
      case DebtStatus.rejected:
        return 'Отклонён';
    }
  }

  factory Debt.fromMap(Map<String, dynamic> data) {
    return Debt(
      id: data['id'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      creatorPhone: data['creatorPhone'] ?? '',
      creatorName: data['creatorName'] ?? '',
      participantPhone: data['participantPhone'] ?? '',
      participantUid: data['participantUid'],
      participantName: data['participantName'],
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      status: _parseStatus(data['status']),
      confirmations: Map<String, bool>.from(data['confirmations'] ?? {}),
      archived: data['archived'] ?? false,
    );
  }

  static DebtStatus _parseStatus(String? value) {
    switch (value) {
      case 'confirmedByCreator':
        return DebtStatus.confirmedByCreator;
      case 'confirmedByParticipant':
        return DebtStatus.confirmedByParticipant;
      case 'closed':
        return DebtStatus.closed;
      case 'rejected':
        return DebtStatus.rejected;
      default:
        return DebtStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorUid': creatorUid,
      'creatorPhone': creatorPhone,
      'creatorName': creatorName,
      'participantPhone': participantPhone,
      'participantUid': participantUid,
      'participantName': participantName,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'closedAt': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'status': status.name,
      'confirmations': confirmations,
      'archived': archived,
    };
  }
}

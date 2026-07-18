import 'package:cloud_firestore/cloud_firestore.dart';

enum DebtStatus { pending, confirmedByCreator, confirmedByParticipant, closed, rejected }

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
  DebtStatus status;
  bool archived;
  final Map<String, bool> confirmations;

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
    DateTime? createdAt,
    this.closedAt,
    this.status = DebtStatus.pending,
    this.archived = false,
    Map<String, bool>? confirmations,
  })  : createdAt = createdAt ?? DateTime.now(),
        confirmations = confirmations ?? {'creator': false, 'participant': false};

  bool get isClosed => status == DebtStatus.closed || status == DebtStatus.rejected;

  String get statusLabel {
    switch (status) {
      case DebtStatus.pending:
        return 'Ожидает';
      case DebtStatus.confirmedByCreator:
        return 'Подтверждено вами';
      case DebtStatus.confirmedByParticipant:
        return 'Подтверждено другом';
      case DebtStatus.closed:
        return 'Закрыт';
      case DebtStatus.rejected:
        return 'Отклонён';
    }
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] ?? '',
      creatorUid: map['creatorUid'] ?? '',
      creatorPhone: map['creatorPhone'] ?? '',
      creatorName: map['creatorName'] ?? '',
      participantPhone: map['participantPhone'] ?? '',
      participantUid: map['participantUid'],
      participantName: map['participantName'],
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      closedAt: (map['closedAt'] as Timestamp?)?.toDate(),
      status: _parseStatus(map['status']),
      archived: map['archived'] ?? false,
      confirmations: Map<String, bool>.from(map['confirmations'] ?? {'creator': false, 'participant': false}),
    );
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
      'closedAt:': closedAt != null ? Timestamp.fromDate(closedAt!) : null,
      'status': status.name,
      'archived': archived,
      'confirmations': confirmations,
    };
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
}

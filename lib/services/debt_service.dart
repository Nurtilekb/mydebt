import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _debtsRef => _firestore.collection('debts');
  CollectionReference get _usersRef => _firestore.collection('users');

  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    final snapshot =
        await _usersRef.where('phone', isEqualTo: normalized).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data() as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> createDebt({
    required String creatorUid,
    required String creatorPhone,
    required String creatorName,
    required String participantPhone,
    String? participantName,
    String? participantUid,
    required double amount,
    String? description,
  }) async {
    final docRef = _debtsRef.doc();
    final debt = Debt(
      id: docRef.id,
      creatorUid: creatorUid,
      creatorPhone: normalizePhone(creatorPhone),
      creatorName: creatorName,
      participantPhone: normalizePhone(participantPhone),
      participantUid: participantUid,
      participantName: participantName,
      amount: amount,
      description: description,
      createdAt: DateTime.now(),
    );
    await docRef.set(debt.toMap());
  }

  Stream<List<Debt>> getMyCreatedDebts(String userPhone) {
    final normalized = normalizePhone(userPhone);
    return _debtsRef
        .where('creatorPhone', isEqualTo: normalized)
        .where('archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>))
          .where((d) => !d.isClosed)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<Debt>> getParticipantDebts(String userPhone) {
    final normalized = normalizePhone(userPhone);
    return _debtsRef
        .where('participantPhone', isEqualTo: normalized)
        .where('archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>))
          .where((d) => !d.isClosed)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<Debt>> getArchivedDebts(String userPhone) {
    final normalized = normalizePhone(userPhone);
    return _debtsRef
        .where('archived', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>))
          .where((debt) =>
              debt.creatorPhone == normalized ||
              debt.participantPhone == normalized)
          .toList()
        ..sort((a, b) =>
            b.closedAt?.compareTo(a.closedAt ?? DateTime.now()) ?? 0);
    });
  }

  Future<void> confirmDebt(String debtId, String role) async {
    final docRef = _debtsRef.doc(debtId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final debt = Debt.fromMap(doc.data() as Map<String, dynamic>);
    final newConfirmations = Map<String, bool>.from(debt.confirmations);
    newConfirmations[role] = true;

    if (newConfirmations['creator'] == true &&
        newConfirmations['participant'] == true) {
      await docRef.update({
        'confirmations': newConfirmations,
        'status': DebtStatus.closed.name,
        'closedAt': Timestamp.fromDate(DateTime.now()),
        'archived': true,
      });
    } else {
      String newStatus;
      if (role == 'creator') {
        newStatus = DebtStatus.confirmedByCreator.name;
      } else {
        newStatus = DebtStatus.confirmedByParticipant.name;
      }
      await docRef.update({
        'confirmations': newConfirmations,
        'status': newStatus,
      });
    }
  }

  Future<void> rejectDebt(String debtId) async {
    await _debtsRef.doc(debtId).update({
      'status': DebtStatus.rejected.name,
      'archived': true,
      'closedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteDebt(String debtId) async {
    await _debtsRef.doc(debtId).delete();
  }

  Future<Debt?> getDebtById(String debtId) async {
    final doc = await _debtsRef.doc(debtId).get();
    if (doc.exists) {
      return Debt.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<Debt?> watchDebt(String debtId) {
    return _debtsRef.doc(debtId).snapshots().map((doc) {
      if (doc.exists) {
        return Debt.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get all registered users (for contacts list)
  Stream<List<Map<String, dynamic>>> getRegisteredUsers() {
    return _usersRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'uid': doc.id,
                'name': doc['displayName'] ?? doc['name'] ?? 'Без имени',
                'phone': doc['phone'] ?? '',
              })
          .toList();
    });
  }
}

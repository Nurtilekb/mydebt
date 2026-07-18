import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';
import '../models/user_model.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _debtsRef => _firestore.collection('debts');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Normalize phone number
  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  // Find user by phone
  Future<UserModel?> findUserByPhone(String phone) async {
    final normalized = normalizePhone(phone);
    final snapshot = await _usersRef.where('phone', isEqualTo: normalized).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Create a debt
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
    );
    await docRef.set(debt.toMap());
  }

  // Get active debts where user is creator or participant
  Stream<List<Debt>> getActiveDebts(String userPhone) {
    final normalized = normalizePhone(userPhone);
    return _debtsRef
        .where('archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>))
          .where((debt) =>
              !debt.isClosed &&
              (debt.creatorPhone == normalized ||
                  debt.participantPhone == normalized))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Get debts where user is creator (I owe me)
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

  // Get debts where user is participant (I owe someone)
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

  // Get archived debts (history)
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
        ..sort((a, b) => b.closedAt?.compareTo(a.closedAt ?? DateTime.now()) ?? 0);
    });
  }

  // Confirm a debt by role
  Future<void> confirmDebt(String debtId, String role) async {
    final docRef = _debtsRef.doc(debtId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final debt = Debt.fromMap(doc.data() as Map<String, dynamic>);

    final newConfirmations = Map<String, bool>.from(debt.confirmations);
    newConfirmations[role] = true;

    String newStatus;
    if (role == 'creator') {
      newStatus = DebtStatus.confirmedByCreator.name;
    } else {
      newStatus = DebtStatus.confirmedByParticipant.name;
    }

    // Check if both confirmed
    if (newConfirmations['creator'] == true && newConfirmations['participant'] == true) {
      await docRef.update({
        'confirmations': newConfirmations,
        'status': DebtStatus.closed.name,
        'closedAt': Timestamp.fromDate(DateTime.now()),
        'archived': true,
      });
    } else {
      await docRef.update({
        'confirmations': newConfirmations,
        'status': newStatus,
      });
    }
  }

  // Reject a debt
  Future<void> rejectDebt(String debtId) async {
    await _debtsRef.doc(debtId).update({
      'status': DebtStatus.rejected.name,
      'archived': true,
      'closedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete a debt from history
  Future<void> deleteDebt(String debtId) async {
    await _debtsRef.doc(debtId).delete();
  }

  // Get debt by ID
  Future<Debt?> getDebtById(String debtId) async {
    final doc = await _debtsRef.doc(debtId).get();
    if (doc.exists) {
      return Debt.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Listen to a single debt
  Stream<Debt?> watchDebt(String debtId) {
    return _debtsRef.doc(debtId).snapshots().map((doc) {
      if (doc.exists) {
        return Debt.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}

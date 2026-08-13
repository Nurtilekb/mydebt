import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

class DebtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _debtsRef => _firestore.collection('debts');
  CollectionReference get _usersRef => _firestore.collection('users');

  String _digitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }

  // ── Users ──

  Stream<List<Map<String, dynamic>>> getRegisteredUsers() {
    print('DebtService: getRegisteredUsers called');
    return _usersRef.snapshots().map((snapshot) {
      final users = <Map<String, dynamic>>[];
      print('DebtService: Found ${snapshot.docs.length} user documents');
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('DebtService: Processing user ${doc.id}, data keys: ${data.keys.toList()}');
          final phone = (data['phone'] ?? '').toString();
          String name = (data['displayName'] ?? '').toString();
          if (name.isEmpty) {
            name = (data['email'] ?? '').toString();
          }
          if (name.isEmpty) {
            name = phone.isNotEmpty ? phone : 'Пользователь';
          }
          final userData = {'uid': doc.id, 'name': name, 'phone': phone};
          print('DebtService: User data: $userData');
          users.add(userData);
        } catch (e) {
          print('Error processing user doc ${doc.id}: $e');
        }
      }
      print('DebtService: Returning ${users.length} users');
      return users;
    });
  }

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final queryDigits = _digitsOnly(phone);
    if (queryDigits.isEmpty) return null;

    // Try exact match first
    var snapshot = await _usersRef
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return {'uid': snapshot.docs.first.id, ...data};
    }

    // Fallback: compare digits only across all users
    snapshot = await _usersRef.get();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final storedDigits = _digitsOnly((data['phone'] ?? '').toString());
      if (storedDigits == queryDigits) {
        return {'uid': doc.id, ...data};
      }
    }

    return null;
  }

  // ── Debts ──

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
      creatorPhone: _digitsOnly(creatorPhone),
      creatorName: creatorName,
      participantPhone: _digitsOnly(participantPhone),
      participantUid: participantUid,
      participantName: participantName,
      amount: amount,
      description: description,
      createdAt: DateTime.now(),
    );
    await docRef.set(debt.toMap());
  }

  Stream<List<Debt>> getMyCreatedDebts(String userPhone) {
    final normalized = _digitsOnly(userPhone);
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
    final normalized = _digitsOnly(userPhone);
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
    final normalized = _digitsOnly(userPhone);
    return _debtsRef.where('archived', isEqualTo: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Debt.fromMap(doc.data() as Map<String, dynamic>))
          .where(
            (debt) =>
                debt.creatorPhone == normalized ||
                debt.participantPhone == normalized,
          )
          .toList()
        ..sort(
          (a, b) => b.closedAt?.compareTo(a.closedAt ?? DateTime.now()) ?? 0,
        );
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
}

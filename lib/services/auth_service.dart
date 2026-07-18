import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> sendOtp(
    String phoneNumber,
    Function(String verificationId, int? resendToken) onCodeSent,
    Function(String error) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Ошибка верификации');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<bool> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
        await _saveFcmToken();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set(UserModel(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        displayName: user.displayName,
      ).toMap());
    } else {
      await doc.update({'phone': user.phoneNumber});
    }
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'fcmToken': token,
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', token);
      }
    } catch (e) {
      // FCM token save failed
    }
  }

  Future<void> refreshFcmToken() async {
    await _saveFcmToken();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

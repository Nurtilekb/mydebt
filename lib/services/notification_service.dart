import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification if needed
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle notification tap
  }

  // Send notification to a user
  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // In production, this should be done via Cloud Functions
    // For now, we store the notification intent in Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'token': fcmToken,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // Get user's notifications
  Stream<QuerySnapshot> getUserNotifications(String fcmToken) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('token', isEqualTo: fcmToken)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}

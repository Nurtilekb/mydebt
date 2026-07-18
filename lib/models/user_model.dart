import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String? displayName;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.phone,
    this.displayName,
    this.fcmToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      displayName: map['displayName'],
      fcmToken: map['fcmToken'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'displayName': displayName,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({String? displayName, String? fcmToken}) {
    return UserModel(
      uid: uid,
      phone: phone,
      displayName: displayName ?? this.displayName,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}

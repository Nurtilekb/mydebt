import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  Future<List<Contact>> getContacts() async {
    if (!await requestPermission()) {
      return [];
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts
          .where((c) => c.phones.isNotEmpty)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      return [];
    }
  }

  Future<List<Contact>> searchContacts(String query) async {
    if (!await requestPermission()) {
      return [];
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );
      return contacts
          .where((c) =>
              c.phones.isNotEmpty &&
              c.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  String formatPhone(String phone) {
    // Remove all non-digit characters except +
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return digits;
  }
}

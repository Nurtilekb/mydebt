import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/debt_service.dart';
import '../services/contact_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class CreateDebtScreen extends StatefulWidget {
  const CreateDebtScreen({super.key});

  @override
  State<CreateDebtScreen> createState() => _CreateDebtScreenState();
}

class _CreateDebtScreenState extends State<CreateDebtScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactService = ContactService();
  bool _loading = false;
  bool _searchingContact = false;
  Contact? _selectedContact;
  String? _participantUid;
  String? _participantName;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _openContactPicker() async {
    setState(() => _searchingContact = true);
    final contacts = await _contactService.getContacts();
    setState(() => _searchingContact = false);

    if (!mounted) return;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет контактов или нет разрешения')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Выберите контакт',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  final phone = contact.phones.first.number;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(phone, style: TextStyle(color: Colors.grey[600])),
                      onTap: () {
                        Navigator.pop(context);
                        _selectContact(contact);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectContact(Contact contact) {
    setState(() {
      _selectedContact = contact;
      _phoneController.text = _contactService.formatPhone(
        contact.phones.first.number,
      );
      _participantName = contact.displayName;
    });
    _lookupParticipant();
  }

  void _lookupParticipant() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _loading = true);

    final debtService = context.read<DebtService>();
    final user = await debtService.findUserByPhone(phone);

    setState(() {
      _loading = false;
      _participantUid = user?.uid;
      if (user != null && _participantName == null) {
        _participantName = user.displayName ?? phone;
      }
    });
  }

  void _createDebt() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Введите корректную сумму');
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Выберите контакт или введите номер');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final debtService = context.read<DebtService>();
      final user = authService.currentUser;

      if (user == null) {
        setState(() => _error = 'Необходима авторизация');
        return;
      }

      await debtService.createDebt(
        creatorUid: user.uid,
        creatorPhone: user.phoneNumber!,
        creatorName: user.displayName ?? user.phoneNumber!,
        participantPhone: phone,
        participantName: _participantName,
        participantUid: _participantUid,
        amount: amount,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Send notification to participant
      if (_participantUid != null) {
        final participantDoc = await debtService.findUserByPhone(phone);
        if (participantDoc?.fcmToken != null) {
          await NotificationService().sendNotification(
            fcmToken: participantDoc!.fcmToken!,
            title: 'Новый долг',
            body: '${user.displayName ?? user.phoneNumber} создал долг на ${amount.toStringAsFixed(0)} ₽',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Долг создан')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый долг'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0 ₽',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Описание (необязательно)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),

            // Contact selection
            Text(
              'Кому должны',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Contact picker button
            OutlinedButton.icon(
              onPressed: _searchingContact ? null : _openContactPicker,
              icon: _searchingContact
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.contacts),
              label: Text(_selectedContact != null
                  ? _selectedContact!.displayName
                  : 'Выбрать из контактов'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Or manual phone input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Или введите номер',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: _phoneController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _lookupParticipant,
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _selectedContact = null;
                  _participantName = null;
                });
              },
            ),

            // Participant status
            if (_participantUid != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Пользователь найден в приложении',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ],
                ),
              ),

            if (_participantUid == null && _phoneController.text.isNotEmpty && !_loading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Пользователь не зарегистрирован',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Error
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // Create button
            ElevatedButton(
              onPressed: _loading ? null : _createDebt,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать долг', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

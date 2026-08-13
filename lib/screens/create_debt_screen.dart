import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/debt_service.dart';
import '../services/auth_service.dart';
import '../models/debt_model.dart';

class CreateDebtScreen extends StatefulWidget {
  final DebtType debtType;
  
  const CreateDebtScreen({super.key, this.debtType = DebtType.owedToMe});

  @override
  State<CreateDebtScreen> createState() => _CreateDebtScreenState();
}

class _CreateDebtScreenState extends State<CreateDebtScreen> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedFriendPhone;
  String? _selectedFriendName;
  String? _selectedFriendUid;

  List<Map<String, dynamic>> _allContacts = [];
  bool _isLoadingContacts = false;
  bool _isSearchingPhone = false;
  String? _phoneSearchError;

  List<Map<String, dynamic>> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allContacts;
    return _allContacts.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final phone = (c['phone'] as String? ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadRegisteredContacts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisteredContacts() async {
    setState(() => _isLoadingContacts = true);
    try {
      final usersSnap = await context
          .read<DebtService>()
          .getRegisteredUsers()
          .first;
      final currentUser = context.read<AuthService>().currentUser;
      final currentUid = currentUser?.uid ?? '';

      setState(() {
        _allContacts = usersSnap.where((u) => u['uid'] != currentUid).toList();
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _searchByPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneSearchError = 'Введите номер телефона');
      return;
    }

    setState(() {
      _isSearchingPhone = true;
      _phoneSearchError = null;
    });

    try {
      final debtService = context.read<DebtService>();
      final user = await debtService.findUserByPhone(phone);

      if (!mounted) return;

      if (user != null) {
        final currentUser = context.read<AuthService>().currentUser;
        if (user['uid'] == currentUser?.uid) {
          setState(() {
            _isSearchingPhone = false;
            _phoneSearchError = 'Это ваш номер';
          });
          return;
        }
        setState(() {
          _selectedFriendPhone = user['phone'];
          _selectedFriendName =
              user['displayName'] ?? user['name'] ?? 'Без имени';
          _selectedFriendUid = user['uid'];
          _isSearchingPhone = false;
          _phoneSearchError = null;
        });
        Navigator.pop(context);
      } else {
        setState(() {
          _isSearchingPhone = false;
          _phoneSearchError = 'Пользователь не зарегистрирован';
        });
      }
    } catch (e) {
      setState(() {
        _isSearchingPhone = false;
        _phoneSearchError = 'Ошибка поиска';
      });
    }
  }

  void _selectContact(Map<String, dynamic> contact) {
    setState(() {
      _selectedFriendPhone = contact['phone'];
      _selectedFriendName = contact['name'];
      _selectedFriendUid = contact['uid'];
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine button text and colors based on debt type
    final buttonText = widget.debtType == DebtType.owedToMe 
        ? 'Мне должны' 
        : 'Я должен';
    final buttonColor = widget.debtType == DebtType.owedToMe
        ? const Color(0xFF007AFF)
        : const Color(0xFFFF3B30);
    final titleText = widget.debtType == DebtType.owedToMe
        ? 'Новый долг (мне должны)'
        : 'Новый долг (я должен)';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: isDark ? Colors.white : Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          titleText,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected contact display
            GestureDetector(
              onTap: _showContactPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedFriendName != null
                        ? buttonColor
                        : isDark ? const Color(0xFF3A3A3C) : Colors.grey[300]!,
                    width: _selectedFriendName != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _selectedFriendName != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFriendName!,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedFriendPhone ?? '',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF8E8E93) : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Выбрать контакт',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF8E8E93) : Colors.grey,
                                fontSize: 17,
                              ),
                            ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isDark ? const Color(0xFF8E8E93) : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[300]!),
              ),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  filled: true,
                  border: InputBorder.none,
                  hintText: 'Сумма',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[300]!),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  border: InputBorder.none,
                  hintText: 'Комментарий (необязательно)',
                  hintStyle: TextStyle(color: isDark ? const Color(0xFF8E8E93) : Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Create button
            ElevatedButton(
              onPressed: _createDebt,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _phoneController.clear();
    _searchController.clear();
    setState(() {
      _phoneSearchError = null;
      _isSearchingPhone = false;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Выберите контакт',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),

                // ========== SECTION 1: Search contacts by name ==========
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                ),

                const SizedBox(height: 8),

                // Registered contacts list
                if (_isLoadingContacts)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allContacts.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Нет зарегистрированных контактов.\nДобавьте по номеру телефона ниже.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: _filteredContacts.isEmpty
                        ? Center(
                            child: Text(
                              'Контакты не найдены',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredContacts.length,
                            itemBuilder: (ctx, i) {
                              final contact = _filteredContacts[i];
                              final isSelected =
                                  _selectedFriendUid == contact['uid'];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blue[50]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected
                                        ? Colors.blue[200]
                                        : Colors.blue[100],
                                    child: Text(
                                      (contact['name'] as String).isNotEmpty
                                          ? (contact['name'] as String)[0]
                                                .toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    contact['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),

                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.blue,
                                        )
                                      : null,
                                  onTap: () {
                                    setSheetState(() {});
                                    _selectContact(contact);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createDebt() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите сумму')));
      return;
    }
    if (_selectedFriendPhone == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите контакт')));
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите корректную сумму')));
      return;
    }

    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) return;

      final debtService = context.read<DebtService>();
      await debtService.createDebt(
        creatorUid: user.uid,
        creatorPhone: user.phoneNumber ?? '',
        creatorName: user.displayName ?? 'Пользователь',
        participantPhone: _selectedFriendPhone!,
        participantName: _selectedFriendName,
        participantUid: _selectedFriendUid,
        amount: amount,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        debtType: widget.debtType,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}

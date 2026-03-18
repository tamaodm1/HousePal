import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Khác';
  String _splitType = 'equal'; // equal, custom, ratio
  bool _isLoading = false;
  bool _isLoadingMembers = true;

  // Firebase data - dùng Map thay vì User model
  List<Map<String, dynamic>> _houseMembers = [];
  final Map<String, bool> _selectedMembers =
      {}; // Firebase String ID -> isSelected
  final Map<String, TextEditingController> _customAmountControllers = {};
  String? _currentUserId;
  String? _currentUserName;
  String? _currentHouseId;

  final List<String> _categories = [
    'Ăn uống',
    'Điện nước',
    'Internet',
    'Mua sắm',
    'Di chuyển',
    'Giải trí',
    'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _loadHouseMembers();
  }

  Future<void> _loadHouseMembers() async {
    try {
      _currentUserId = await AuthService.getFirebaseUserId();
      _currentUserName = await AuthService.getCurrentUserName();
      _currentHouseId = await AuthService.getFirebaseHouseId();

      if (_currentHouseId == null || _currentHouseId!.isEmpty) {
        setState(() => _isLoadingMembers = false);
        return;
      }

      final membersData =
          await FirestoreService.getHouseMembers(_currentHouseId!);

      setState(() {
        _houseMembers = membersData;
        // Mặc định chọn tất cả thành viên - dùng Firebase String ID
        for (var member in membersData) {
          final memberId = member['id'] as String;
          _selectedMembers[memberId] = true;
          _customAmountControllers[memberId] = TextEditingController();
        }
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() => _isLoadingMembers = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  double _calculateSplitAmount() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    if (selectedCount == 0) return 0;
    return amount / selectedCount;
  }

  Future<void> _saveExpense() async {
    if (_descriptionController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập đầy đủ thông tin'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final selectedUserIds = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 người chia tiền'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_currentHouseId == null || _currentHouseId!.isEmpty) {
        throw Exception('Chưa tham gia phòng nào');
      }

      final amount =
          double.tryParse(_amountController.text.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        throw Exception('Số tiền không hợp lệ');
      }

      // Tạo custom splits nếu chọn chia tùy chỉnh hoặc theo tỷ lệ
      List<Map<String, dynamic>>? customSplits;
      if (_splitType == 'custom' || _splitType == 'ratio') {
        customSplits = [];
        for (var memberId in selectedUserIds) {
          final customAmount = double.tryParse(
                  _customAmountControllers[memberId]
                          ?.text
                          .replaceAll(',', '') ??
                      '0') ??
              0;
          if (customAmount > 0) {
            customSplits.add({
              'userId': memberId,
              'amount': customAmount,
            });
          }
        }
      }

      // Build splits với Firebase String IDs
      final splitAmount = amount / selectedUserIds.length;
      final splits = <Map<String, dynamic>>[];

      // Nếu chia theo tỷ lệ, tính tổng tỷ lệ trước
      double totalRatio = 0;
      if (_splitType == 'ratio') {
        for (var memberId in selectedUserIds) {
          final ratio = double.tryParse(
                _customAmountControllers[memberId]?.text.replaceAll(',', '') ??
                    '0',
              ) ??
              0;
          if (ratio > 0) totalRatio += ratio;
        }
        if (totalRatio <= 0) {
          throw Exception('Vui lòng nhập tỷ lệ hợp lệ (> 0)');
        }
      }

      for (var member in _houseMembers) {
        final memberId = member['id'] as String;
        if (_selectedMembers[memberId] == true) {
          double memberAmount = splitAmount;
          if (_splitType == 'custom' && customSplits != null) {
            final custom = customSplits.firstWhere(
              (s) => s['userId'] == memberId,
              orElse: () => {'amount': splitAmount},
            );
            memberAmount = (custom['amount'] as num).toDouble();
          } else if (_splitType == 'ratio') {
            final ratio = double.tryParse(
                  _customAmountControllers[memberId]
                          ?.text
                          .replaceAll(',', '') ??
                      '0',
                ) ??
                0;
            memberAmount = totalRatio > 0 ? (amount * ratio / totalRatio) : 0;
          }
          splits.add({
            'userId': memberId,
            'userName': member['name'] ?? 'Unknown',
            'amount': memberAmount,
          });
        }
      }

      await FirestoreService.createExpenseWithSplit(
        houseId: _currentHouseId!,
        paidByUserId: _currentUserId!,
        paidByName: _currentUserName ?? 'Unknown',
        description: _descriptionController.text,
        amount: amount,
        category: _selectedCategory,
        splitType: _splitType,
        splitWith: splits,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã thêm chi tiêu thành công!'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chi tiêu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên chi tiêu
                  Text('Tên chi tiêu *',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Tiền điện, Đi chợ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Số tiền
                  Text('Số tiền *',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền',
                      suffixText: 'đ',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Danh mục
                  Text('Danh mục',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value ?? 'Khác'),
                  ),
                  const SizedBox(height: 24),

                  // Người trả tiền
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Người trả tiền',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                              _currentUserName ?? 'Bạn',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cách chia tiền
                  Text('Cách chia tiền',
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSplitTypeButton(
                            'equal', 'Chia đều', Icons.people),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSplitTypeButton(
                            'custom', 'Tùy chỉnh', Icons.edit),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSplitTypeButton(
                            'ratio', 'Tỷ lệ', Icons.pie_chart),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Chọn người chia tiền
                  Text(
                    'Chia tiền cho (${_selectedMembers.values.where((v) => v).length} người)',
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildMembersList(),
                  const SizedBox(height: 24),

                  // Tóm tắt
                  if (_amountController.text.isNotEmpty) _buildSummary(),
                  const SizedBox(height: 24),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Thêm chi tiêu',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSplitTypeButton(String type, String label, IconData icon) {
    final isSelected = _splitType == type;
    return InkWell(
      onTap: () => setState(() => _splitType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.black : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    if (_houseMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Không có thành viên nào trong phòng'),
      );
    }

    return Column(
      children: _houseMembers.map((member) {
        final memberId = member['id'] as String;
        final memberName = member['name'] as String? ?? 'Unknown';
        final avatarUrl = (member['avatarUrl'] ?? '').toString();
        final avatarBase64 = (member['avatarBase64'] ?? '').toString();
        final isSelected = _selectedMembers[memberId] ?? false;
        final isCurrentUser = memberId == _currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedMembers[memberId] = value ?? false;
              });
            },
            title: Row(
              children: [
                UserAvatar(
                  name: memberName,
                  avatarUrl: avatarUrl,
                  avatarBase64: avatarBase64,
                  radius: 16,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memberName + (isCurrentUser ? ' (Bạn)' : ''),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (_splitType == 'equal' && isSelected)
                        Text(
                          'Nợ: ${_formatMoney(_calculateSplitAmount())}đ',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle:
                (_splitType == 'custom' || _splitType == 'ratio') && isSelected
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextField(
                          controller: _customAmountControllers[memberId],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: _splitType == 'custom'
                                ? 'Số tiền nợ'
                                : 'Tỷ lệ (vd: 1, 2, 3)',
                            suffixText: _splitType == 'custom' ? 'đ' : 'phần',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      )
                    : null,
            activeColor: AppColors.primary,
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.trailing,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummary() {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    final splitAmount = selectedCount > 0 ? amount / selectedCount : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Tóm tắt',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng tiền:'),
              Text('${_formatMoney(amount)}đ',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số người chia:'),
              Text('$selectedCount người'),
            ],
          ),
          if (_splitType == 'equal') ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mỗi người nợ:'),
                Text('${_formatMoney(splitAmount.toDouble())}đ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ],
          if (_splitType == 'ratio')
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Tiền sẽ được chia theo tỷ lệ từng người nhập.',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ),
        ],
      ),
    );
  }
}

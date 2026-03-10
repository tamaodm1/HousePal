import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AddChoreScreen extends StatefulWidget {
  const AddChoreScreen({super.key});

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _choreNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _points = 10;
  String _frequency = 'daily';
  String? _assignedUserId;
  String? _assignedUserName;
  List<Map<String, dynamic>> _houseMembers = [];
  bool _isLoading = false;
  final Map<String, String> frequencyMap = {
    'Hằng ngày': 'daily',
    'Hằng tuần': 'weekly',
    'Hằng tháng': 'monthly'
  };
  final List<String> frequencies = ['Hằng ngày', 'Hằng tuần', 'Hằng tháng'];

  @override
  void initState() {
    super.initState();
    _loadHouseMembers();
  }

  Future<void> _loadHouseMembers() async {
    try {
      final houseId = await AuthService.getFirebaseHouseId();
      if (houseId == null || houseId.isEmpty) return;

      final members = await FirestoreService.getHouseMembers(houseId);
      
      setState(() {
        _houseMembers = members;
      });
    } catch (e) {
      print('Lỗi load members: $e');
    }
  }

  @override
  void dispose() {
    _choreNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChore() async {
    if (_choreNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên việc nhà')),
      );
      return;
    }

    if (_assignedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn người được phân công')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final houseId = await AuthService.getFirebaseHouseId();
      if (houseId == null || houseId.isEmpty) {
        throw Exception('Chưa tham gia phòng nào');
      }

      // Tạo chore trong Firebase
      final choreId = await FirestoreService.createChore({
        'title': _choreNameController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'frequency': _frequency,
        'points': _points,
        'houseId': houseId,
        'isActive': true,
      });
      
      // Assign chore to selected user
      await FirestoreService.assignChore(choreId, _assignedUserId!, _assignedUserName ?? '');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo và giao việc thành công!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
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
        title: const Text('Tạo việc nhà mới'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên việc nhà
            const Text('Tên việc nhà', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _choreNameController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Đổ rác, Lau nhà',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Tần suất
            const Text('Tần suất', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: 'Hằng ngày',
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: frequencies
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) => setState(() => _frequency = frequencyMap[value] ?? 'daily'),
            ),
            const SizedBox(height: 16),

            // Điểm thưởng
            const Text('Điểm thưởng', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _points,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 điểm (Dễ)')),
                DropdownMenuItem(value: 10, child: Text('10 điểm (Trung bình)')),
                DropdownMenuItem(value: 20, child: Text('20 điểm (Khó)')),
              ],
              onChanged: (value) => setState(() => _points = value ?? 10),
            ),
            const SizedBox(height: 16),

            // Mô tả
            const Text('Mô tả chi tiết', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập mô tả chi tiết...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Người được phân công
            const Text('Người được phân công', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _assignedUserId,
              decoration: InputDecoration(
                hintText: 'Chọn người làm việc này',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _houseMembers
                  .map((user) => DropdownMenuItem<String>(
                        value: user['id']?.toString(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary.withOpacity(0.2),
                              child: Text(
                                (user['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(user['name'] ?? 'Unknown'),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                final selectedUser = _houseMembers.firstWhere(
                  (u) => u['id']?.toString() == value, 
                  orElse: () => <String, dynamic>{},
                );
                setState(() {
                  _assignedUserId = value;
                  _assignedUserName = selectedUser['name'];
                });
              },
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChore,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Tạo việc nhà'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

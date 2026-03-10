import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AddShoppingItemScreen extends StatefulWidget {
  const AddShoppingItemScreen({super.key});

  @override
  State<AddShoppingItemScreen> createState() => _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends State<AddShoppingItemScreen> {
  final _itemNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên món đó')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final houseId = await AuthService.getFirebaseHouseId();
      final userId = await AuthService.getFirebaseUserId();
      final userName = await AuthService.getCurrentUserName();
      
      if (houseId == null || houseId.isEmpty) {
        throw Exception('Chưa tham gia phòng nào');
      }

      await FirestoreService.createShoppingItem({
        'name': _itemNameController.text,
        'houseId': houseId,
        'addedBy': userId,
        'addedByName': userName ?? 'Người dùng',
        'isPurchased': false,
      });
      
      if (mounted) {
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
        title: const Text('Thêm vào danh sách'),
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
            // Tên món đó
            const Text('Tên món đó', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Sữa tươi, Bánh mì',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
                    onPressed: _isLoading ? null : _saveItem,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Thêm vào danh sách'),
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

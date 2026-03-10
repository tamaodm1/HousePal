import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPinned = false;
  bool _isLoading = false;
  final List<String> noteTypes = ['Ghi chú', 'Quản trị', 'Thông tin'];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
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

      await FirestoreService.createNote({
        'title': _titleController.text,
        'content': _contentController.text,
        'houseId': houseId,
        'createdBy': userId,
        'createdByName': userName ?? 'Người dùng',
        'isPinned': _isPinned,
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
        title: const Text('Thêm ghi chú'),
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
            // Tiêu đề
            const Text('Tiêu đề', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Nhập tiêu đề ghi chú',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Nội dung
            const Text('Nội dung', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung ghi chú...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Ghim ghi chú
            CheckboxListTile(
              title: const Text('Ghim ghi chú'),
              subtitle: const Text('Hiển thị ở đầu danh sách'),
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value ?? false),
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
                    onPressed: _isLoading ? null : _saveNote,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Thêm ghi chú'),
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

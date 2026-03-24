import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String _selectedCategory = 'news';
  String? _userId;
  String? _userName;
  String? _userAvatarUrl;
  String? _userAvatarBase64;
  String? _houseId;
  String? _houseName;
  File? _pickedImage;
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'news', 'label': '📰 Tin tức', 'color': '0xFF4CAF50'},
    {'value': 'help', 'label': '🆘 Cần giúp', 'color': '0xFFFFC107'},
    {'value': 'market', 'label': '🛒 Chợ', 'color': '0xFF2196F3'},
    {'value': 'event', 'label': '🎉 Sự kiện', 'color': '0xFF9C27B0'},
    {'value': 'roommate', 'label': '👥 Tìm bạn', 'color': '0xFFE91E63'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = await AuthService.getFirebaseUserId();
      final userName = await AuthService.getCurrentUserName();
      final houseId = await AuthService.getFirebaseHouseId();
      
      // TODO: Get house name from Firebase
      
      String? avatarUrl;
      String? avatarBase64;
      if (userId != null && userId.isNotEmpty) {
        final userDoc = await FirestoreService.getUser(userId);
        avatarUrl = (userDoc?['avatarUrl'] ?? '').toString();
        if (avatarUrl.isEmpty) avatarUrl = null;
        avatarBase64 = (userDoc?['avatarBase64'] ?? '').toString();
        if (avatarBase64.isEmpty) avatarBase64 = null;
      }
      
      setState(() {
        _userId = userId;
        _userName = userName;
        _houseId = houseId;
        _houseName = 'My House'; // Placeholder
        _userAvatarUrl = avatarUrl;
        _userAvatarBase64 = avatarBase64;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền tiêu đề và nội dung'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_userId == null || _houseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông tin người dùng không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_pickedImage != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'posts/$_houseId/$fileName';
        imageUrl = await StorageService.uploadFile(path: storagePath, file: _pickedImage!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi upload ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }
    }

    try {
      await FeedService.createPost(
        authorId: _userId!,
        authorName: _userName ?? 'Anonymous',
        houseId: _houseId!,
        houseName: _houseName ?? 'My House',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl,
        avatarUrl: _userAvatarUrl,
        avatarBase64: _userAvatarBase64,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng bài thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài post'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selection
            const Text(
              'Chọn danh mục',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['value'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = cat['value']!);
                  },
                  selectedColor: AppColors.primary.withOpacity(0.3),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Tiêu đề',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Nhập tiêu đề bài post...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),

            // Content
            const Text(
              'Nội dung',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Nhập nội dung bài post...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Đăng bài',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

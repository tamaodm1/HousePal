import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/message.dart';
import '../../services/messaging_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final bool embed;

  const ChatScreen({super.key, this.embed = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _houseId;
  String? _userId;
  String? _userName;
  String? _avatarUrl;
  String? _avatarBase64;
  File? _pickedImage;
  bool _isLoading = true;
  bool _isUploading = false;

  Future<void> _loadUserInfo() async {
    try {
      final houseId = await AuthService.getFirebaseHouseId();
      final userId = await AuthService.getFirebaseUserId();
      final userName = await AuthService.getCurrentUserName();

      String? avatarUrl;
      String? avatarBase64;
      if (userId != null && userId.isNotEmpty) {
        final userDoc = await FirestoreService.getUser(userId);
        avatarUrl = (userDoc?['avatarUrl'] ?? '').toString();
        if (avatarUrl.isEmpty) avatarUrl = null;
        avatarBase64 = (userDoc?['avatarBase64'] ?? '').toString();
        if (avatarBase64.isEmpty) avatarBase64 = null;
        print('Loaded user avatar: url=$avatarUrl, base64=${avatarBase64 != null ? 'present' : 'null'}');
      }

      setState(() {
        _houseId = houseId;
        _userId = userId;
        _userName = userName;
        _avatarUrl = avatarUrl;
        _avatarBase64 = avatarBase64;
        _isLoading = false;
      });
    } catch (e) {
      print('Load user info error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _pickImage() async {
    try {
      // Skip image picker on web due to Storage issues
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gửi ảnh chưa hỗ trợ trên web. Vui lòng dùng ứng dụng di động'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _pickedImage = File(pickedFile.path));
      }
    } catch (e) {
      print('Pick image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    if (_pickedImage == null || kIsWeb) return const SizedBox.shrink();
    return Image.memory(
      _pickedImage!.readAsBytesSync(),
      width: double.infinity,
      height: 140,
      fit: BoxFit.cover,
    );
  }

  Future<void> _sendMessage() async {
    if ((_messageController.text.trim().isEmpty) && _pickedImage == null) return;
    if (_houseId == null || _userId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    String? imageUrl;
    if (_pickedImage != null) {
      setState(() => _isUploading = true);
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'chat/$_houseId/$_userId/$fileName';
        imageUrl = await StorageService.uploadFile(path: storagePath, file: _pickedImage!);
        
        if (imageUrl.isEmpty) {
          throw Exception('Lỗi upload ảnh: không nhận được URL');
        }
      } catch (e) {
        print('Storage upload error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi upload ảnh: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isUploading = false;
          _pickedImage = null;
        });
        return;
      }
    }

    try {
      await MessagingService.sendMessage(
        houseId: _houseId!,
        senderId: _userId!,
        senderName: _userName ?? 'Anonymous',
        content: messageText.isEmpty && imageUrl != null ? '📷 Ảnh' : messageText,
        avatarUrl: _avatarUrl,
        avatarBase64: _avatarBase64,
        imageUrl: imageUrl,
      );
      
      setState(() {
        _isUploading = false;
        _pickedImage = null;
      });
    } catch (e) {
      print('Message send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.embed
          ? const Center(child: CircularProgressIndicator())
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
    }

    if (_houseId == null) {
      return widget.embed
          ? const Center(child: Text('Bạn chưa tham gia phòng nào'))
          : const Scaffold(
              body: Center(child: Text('Bạn chưa tham gia phòng nào')),
            );
    }

    final chatContent = Column(
      children: [
        // Messages List
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: MessagingService.getMessagesStream(_houseId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Chưa có tin nhắn nào'));
              }

              final messages = snapshot.data!;
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isOwn = message.senderId == _userId;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment:
                          isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isOwn)
                          UserAvatar(
                            name: message.senderName,
                            avatarUrl: message.avatarUrl,
                            avatarBase64: message.avatarBase64,
                            radius: 20,
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isOwn
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (!isOwn)
                                Text(
                                  message.senderName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isOwn
                                      ? AppColors.primary
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (message.imageUrl != null &&
                                        message.imageUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          message.imageUrl!,
                                          width: 180,
                                          height: 150,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container(
                                              width: 180,
                                              height: 150,
                                              color: Colors.grey[400],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    if (message.content.isNotEmpty)
                                      Text(
                                        message.content,
                                        style: TextStyle(
                                          color: isOwn
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isOwn)
                          UserAvatar(
                            name: _userName,
                            avatarUrl: _avatarUrl,
                            avatarBase64: _avatarBase64,
                            radius: 20,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Image preview (if any) - disabled on web
        if (_pickedImage != null && !kIsWeb)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildImagePreview(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              if (!kIsWeb)
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.grey),
                  onPressed: _pickImage,
                ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: AppColors.primary,
                onPressed: _isUploading ? null : _sendMessage,
                child: _isUploading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embed) {
      return chatContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Phòng'),
        backgroundColor: AppColors.primary,
      ),
      body: chatContent,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

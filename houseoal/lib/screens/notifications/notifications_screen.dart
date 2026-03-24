import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = await AuthService.getFirebaseUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _notifications = [];
          _isLoading = false;
          _error = 'Bạn chưa đăng nhập';
        });
        return;
      }

      final items = await FirestoreService.getNotificationsByUser(userId);
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => n['isRead'] != true).toList();
    if (unread.isEmpty) return;
    for (final n in unread) {
      if (n['id'] != null) {
        await FirestoreService.markNotificationRead(n['id'] as String);
      }
    }
    await _loadData();
  }

  IconData _iconByType(String type) {
    switch (type) {
      case 'chore':
        return Icons.checklist_rounded;
      case 'expense':
        return Icons.account_balance_wallet_rounded;
      case 'debt':
        return Icons.payments_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _timeAgo(dynamic createdAt) {
    if (createdAt is! DateTime) return 'Vừa xong';
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
    if (diff.inDays < 1) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (!_isLoading && unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Đọc tất cả'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 56, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!, style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final item = _notifications[index];
                          final isRead = item['isRead'] == true;
                          final type = (item['type'] ?? 'info').toString();
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            onTap: () async {
                              if (item['id'] != null && !isRead) {
                                await FirestoreService.markNotificationRead(
                                    item['id'] as String);
                                _loadData();
                              }
                            },
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: isRead
                                  ? Colors.grey.shade200
                                  : AppColors.primary.withOpacity(0.12),
                              child: Icon(
                                _iconByType(type),
                                color: isRead
                                    ? Colors.grey.shade500
                                    : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              (item['title'] ?? 'Thông báo').toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isRead ? FontWeight.w400 : FontWeight.w700,
                                color: isRead ? Colors.black54 : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  (item['message'] ?? '').toString(),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: isRead
                                          ? Colors.black38
                                          : Colors.black54),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _timeAgo(item['createdAt']),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isRead
                                ? const Icon(Icons.check_circle_outline,
                                    color: Colors.grey, size: 18)
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có thông báo nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thông báo sẽ hiện ở đây khi có việc nhà mới, chi tiêu được thêm, hoặc khoản nợ cần thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Làm mới'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

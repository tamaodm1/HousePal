import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../core/constants/colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const ChoresTab(),
    const ExpensesTab(),
    const BulletinTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Trang chủ',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.checklist_rounded,
                  label: 'Công việc',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.wallet_rounded,
                  label: 'Chi tiêu',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.newspaper_rounded,
                  label: 'Bảng tin',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: 'Cá nhân',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab - Giống hệt ảnh
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String? _userName = 'Người dùng';
  String? _currentUserId;
  String? _avatarUrl;
  String? _avatarBase64;
  int _choreCount = 0;
  int _memberCount = 0;
  int _noteCount = 0;
  int _expenseCount = 0;
  int _chorePoints = 0;
  int _pendingShoppingCount = 0;
  int _unreadNotificationCount = 0;
  double _monthlyExpenseTotal = 0;
  int _myTurnChoreCount = 0;
  int _completedTodayCount = 0;
  int _availableChoreCount = 0;
  List<Map<String, dynamic>> _upcomingChores = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getCurrentUserName();
    final userId = await AuthService.getFirebaseUserId();
    final houseId = await AuthService.getFirebaseHouseId();
    _currentUserId = userId;

    try {
      if (houseId != null && houseId.isNotEmpty) {
        // Lấy dữ liệu từ Firebase
        final chores = await FirestoreService.getChoresByHouse(houseId);
        final notes = await FirestoreService.getNotesByHouse(houseId);
        final expenses = await FirestoreService.getExpensesByHouse(houseId);
        final shoppingItems =
            await FirestoreService.getShoppingItemsByHouse(houseId);
        final members = await FirestoreService.getHouseMembers(houseId);

        // Lấy điểm từ user data
        int points = 0;
        String avatarUrl = '';
        String avatarBase64 = '';
        int unreadNotificationCount = 0;
        if (userId != null) {
          final userData = await FirestoreService.getUserById(userId);
          points = (userData?['chorePoints'] as num?)?.toInt() ?? 0;
          avatarUrl = (userData?['avatarUrl'] ?? '').toString();
          avatarBase64 = (userData?['avatarBase64'] ?? '').toString();

          final notifications =
              await FirestoreService.getNotificationsByUser(userId);
          unreadNotificationCount =
              notifications.where((n) => n['isRead'] != true).length;
        }

        final pendingShoppingCount =
            shoppingItems.where((i) => i['isPurchased'] != true).length;
        final monthlyExpenseTotal = _calculateMonthlyExpenseTotal(expenses);

        final myTurnCount = chores.where(_isMyPendingChore).length;
        final completedTodayCount = chores.where(_isCompletedToday).length;
        final availableChoreCount = chores.where((chore) {
          final type = chore['type'] ?? 'recurring';
          return type == 'oneTime' && chore['status'] == 'available';
        }).length;
        final upcomingChores = [...chores]..sort((a, b) {
            final byPriority = _getDashboardChorePriority(a)
                .compareTo(_getDashboardChorePriority(b));
            if (byPriority != 0) return byPriority;
            final aPoints = (a['points'] as num?)?.toInt() ?? 0;
            final bPoints = (b['points'] as num?)?.toInt() ?? 0;
            return bPoints.compareTo(aPoints);
          });

        setState(() {
          _userName = name ?? 'Người dùng';
          _choreCount = chores.length;
          _noteCount = notes.length;
          _expenseCount = expenses.length;
          _memberCount = members.length;
          _chorePoints = points;
          _avatarUrl = avatarUrl;
          _avatarBase64 = avatarBase64;
          _pendingShoppingCount = pendingShoppingCount;
          _unreadNotificationCount = unreadNotificationCount;
          _monthlyExpenseTotal = monthlyExpenseTotal;
          _myTurnChoreCount = myTurnCount;
          _completedTodayCount = completedTodayCount;
          _availableChoreCount = availableChoreCount;
          _upcomingChores = upcomingChores.take(3).toList();
        });
      } else {
        setState(() {
          _userName = name ?? 'Người dùng';
        });
      }
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
      setState(() {
        _userName = name ?? 'Người dùng';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Green Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header Row
                Row(
                  children: [
                    // Avatar
                    _buildDashboardAvatar(),
                    const SizedBox(width: 12),
                    // Greeting
                    Expanded(
                      child: Text(
                        'Chào $_userName !',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Notification Bell
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Điểm thành viên Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Điểm thành viên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$_chorePoints',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2 Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Công việc',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_choreCount',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thành viên',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_memberCount',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tổng quan nhanh',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                _buildNewsCard(
                  title: 'Chi tiêu tháng này',
                  value: '${_formatCompactMoney(_monthlyExpenseTotal)}đ',
                  subtitle:
                      '$_expenseCount khoản chi tiêu • $_noteCount ghi chú',
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 10),
                _buildNewsCard(
                  title: 'Mua sắm cần xử lý',
                  value: '$_pendingShoppingCount mục',
                  subtitle: 'Danh sách mua sắm chưa hoàn tất',
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 10),
                _buildNewsCard(
                  title: 'Thông báo chưa đọc',
                  value: '$_unreadNotificationCount',
                  subtitle: 'Cập nhật mới trong phòng của bạn',
                  icon: Icons.notifications_active_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                // Công việc sắp tới Section
                _buildUpcomingTasksSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _calculateMonthlyExpenseTotal(List<Map<String, dynamic>> expenses) {
    final now = DateTime.now();
    return expenses.where((e) {
      final createdAt = e['createdAt'];
      if (createdAt is! DateTime) return false;
      return createdAt.year == now.year && createdAt.month == now.month;
    }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));
  }

  String _formatCompactMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildNewsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardAvatar() {
    final avatarUrl = (_avatarUrl ?? '').trim();
    final avatarBase64 = (_avatarBase64 ?? '').trim();
    final hasUrlAvatar =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');

    ImageProvider? imageProvider;
    if (avatarBase64.isNotEmpty) {
      try {
        imageProvider = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {
        imageProvider = null;
      }
    }
    if (imageProvider == null && hasUrlAvatar) {
      imageProvider = NetworkImage(avatarUrl);
    }

    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDashboardInitialAvatar(),
              )
            : _buildDashboardInitialAvatar(),
      ),
    );
  }

  Widget _buildDashboardInitialAvatar() {
    return Center(
      child: Text(
        (_userName?.isNotEmpty ?? false) ? _userName![0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildUpcomingTasksSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.assignment_turned_in_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Công việc sắp tới',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ưu tiên những việc cần xử lý sớm nhất trong nhà.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/chores'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('Mở'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildDashboardTaskStatChip(
                icon: Icons.star_rounded,
                label: 'Tới lượt bạn',
                value: _myTurnChoreCount.toString(),
                color: AppColors.primary,
              ),
              _buildDashboardTaskStatChip(
                icon: Icons.check_circle_rounded,
                label: 'Đã xong hôm nay',
                value: _completedTodayCount.toString(),
                color: Colors.green,
              ),
              _buildDashboardTaskStatChip(
                icon: Icons.inbox_rounded,
                label: 'Đang chờ nhận',
                value: _availableChoreCount.toString(),
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingChores.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.celebration_outlined,
                      color: Colors.grey.shade500, size: 30),
                  const SizedBox(height: 8),
                  const Text(
                    'Hiện chưa có việc nào cần ưu tiên',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Khi có việc xoay vòng hoặc việc tự nhận, mục này sẽ tự cập nhật.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            ..._upcomingChores.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            entry.key == _upcomingChores.length - 1 ? 0 : 12),
                    child: _buildUpcomingTaskTile(entry.value,
                        highlight: entry.key == 0),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDashboardTaskStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$value $label',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTaskTile(Map<String, dynamic> chore,
      {bool highlight = false}) {
    final accentColor = _getDashboardChoreAccent(chore);
    final title = chore['title'] ?? 'Công việc';
    final description = chore['description'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            highlight ? accentColor.withOpacity(0.08) : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: highlight
                ? accentColor.withOpacity(0.35)
                : const Color(0xFFE8ECEF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getDashboardChoreIcon(chore), color: accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _getDashboardChoreBadge(chore),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor),
                      ),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _getDashboardChoreStatus(chore),
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMiniMetaChip(
                        _getDashboardFrequencyLabel(chore), accentColor),
                    _buildMiniMetaChip(
                        '${(chore['points'] as num?)?.toInt() ?? 0} điểm',
                        Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  bool _isCompletedToday(Map<String, dynamic> chore) {
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') {
      return chore['status'] == 'completed';
    }

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return chore['lastCompletedDate'] == todayStr;
  }

  bool _isMyPendingChore(Map<String, dynamic> chore) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    if (_isCompletedToday(chore)) return false;

    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') {
      return chore['status'] == 'claimed' &&
          chore['assignedToUserId'] == _currentUserId;
    }
    return chore['currentAssigneeId'] == _currentUserId;
  }

  int _getDashboardChorePriority(Map<String, dynamic> chore) {
    if (_isMyPendingChore(chore)) return 0;
    if (!_isCompletedToday(chore) &&
        (chore['type'] ?? 'recurring') == 'recurring') return 1;
    if ((chore['type'] ?? 'recurring') == 'oneTime' &&
        chore['status'] == 'available') return 2;
    if ((chore['type'] ?? 'recurring') == 'oneTime' &&
        chore['status'] == 'claimed') return 3;
    return 4;
  }

  Color _getDashboardChoreAccent(Map<String, dynamic> chore) {
    if (_isMyPendingChore(chore)) return AppColors.primary;
    if (_isCompletedToday(chore)) return Colors.green;
    if ((chore['type'] ?? 'recurring') == 'oneTime' &&
        chore['status'] == 'available') return Colors.orange;
    return Colors.blue;
  }

  IconData _getDashboardChoreIcon(Map<String, dynamic> chore) {
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') {
      return chore['status'] == 'available'
          ? Icons.volunteer_activism_outlined
          : Icons.person_pin_circle_outlined;
    }
    return _isCompletedToday(chore)
        ? Icons.check_circle_outline_rounded
        : Icons.autorenew_rounded;
  }

  String _getDashboardChoreBadge(Map<String, dynamic> chore) {
    if (_isCompletedToday(chore)) return 'Đã xong';
    if (_isMyPendingChore(chore)) return 'Ưu tiên';

    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') {
      return chore['status'] == 'available' ? 'Chờ nhận' : 'Đang làm';
    }
    return 'Sắp tới';
  }

  String _getDashboardChoreStatus(Map<String, dynamic> chore) {
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') {
      final status = chore['status'] ?? 'available';
      if (status == 'completed') {
        return 'Việc tự nhận này đã được hoàn thành.';
      }
      if (status == 'claimed') {
        final claimedByUserName =
            chore['assignedToUserName'] ?? 'Một thành viên';
        return chore['assignedToUserId'] == _currentUserId
            ? 'Bạn đang nhận việc này, hoàn thành để ghi điểm.'
            : '$claimedByUserName đang xử lý việc này.';
      }
      return 'Chưa có ai nhận, ai rảnh có thể vào xử lý ngay.';
    }

    final assigneeName = chore['currentAssigneeName'] ?? 'Chưa giao';
    if (_isCompletedToday(chore)) {
      return 'Đã hoàn thành hôm nay, sẽ xoay vòng ở kỳ tiếp theo.';
    }
    if (chore['currentAssigneeId'] == _currentUserId) {
      return 'Đến lượt bạn phụ trách việc này trong hôm nay.';
    }
    return 'Hiện đang tới lượt $assigneeName phụ trách.';
  }

  String _getDashboardFrequencyLabel(Map<String, dynamic> chore) {
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') return 'Một lần';

    switch (chore['frequency']) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      default:
        return 'Định kỳ';
    }
  }
}

// ============ CHORES TAB - Hiển thị trực tiếp ============
class ChoresTab extends StatefulWidget {
  const ChoresTab({super.key});

  @override
  State<ChoresTab> createState() => _ChoresTabState();
}

class _ChoresTabState extends State<ChoresTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> recurringChores = [];
  List<Map<String, dynamic>> oneTimeChores = [];
  List<Map<String, dynamic>> leaderboard = [];
  String? currentUserId;
  String? currentUserName;
  String? currentHouseId;
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      currentUserId = await AuthService.getFirebaseUserId();
      currentHouseId = await AuthService.getFirebaseHouseId();

      if (currentHouseId == null || currentHouseId!.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final userData = await FirestoreService.getUserById(currentUserId!);
      currentUserName = userData?['name'] ?? 'User';

      final houseData = await FirestoreService.getHouseById(currentHouseId!);
      isAdmin = houseData?['ownerId'] == currentUserId;

      // Kiểm tra & reset việc qua ngày mới (trừ điểm nếu chưa hoàn thành)
      await FirestoreService.checkAndResetChores(currentHouseId!);

      final recurring =
          await FirestoreService.getRecurringChores(currentHouseId!);
      final oneTime = await FirestoreService.getOneTimeChores(currentHouseId!);
      final members = await FirestoreService.getHouseMembers(currentHouseId!);
      members.sort((a, b) => ((b['chorePoints'] as num?) ?? 0)
          .compareTo((a['chorePoints'] as num?) ?? 0));

      setState(() {
        recurringChores = recurring;
        oneTimeChores = oneTime;
        leaderboard = members;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Green Header - Y HỆT GIAO DIỆN GỐC (bỏ nút back)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Việc nhà',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quản lý và xoay vòng công việc',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Tab Bar - 3 tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Xoay vòng'),
                        Tab(text: 'Tự nhận'),
                        Tab(text: 'Xếp hạng'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecurringTab(),
                      _buildOneTimeTab(),
                      _buildLeaderboardTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddChoreDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  // ============ TAB XOAY VÒNG ============
  Widget _buildRecurringTab() {
    if (recurringChores.isEmpty) {
      return _buildEmptyState('Chưa có việc xoay vòng', Icons.sync_disabled,
          'Việc xoay vòng tự động luân phiên giữa các thành viên');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children:
          recurringChores.map((chore) => _buildRecurringCard(chore)).toList(),
    );
  }

  // ============ TAB TỰ NHẬN ============
  Widget _buildOneTimeTab() {
    final availableChores =
        oneTimeChores.where((c) => c['status'] == 'available').toList();
    final claimedChores =
        oneTimeChores.where((c) => c['status'] == 'claimed').toList();

    if (oneTimeChores.isEmpty) {
      return _buildEmptyState('Chưa có việc cần nhận', Icons.inbox,
          'Việc tự nhận ai muốn làm thì nhận');
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (availableChores.isNotEmpty) ...[
          _buildSectionHeader(
              'Đang chờ nhận', Colors.green, availableChores.length),
          ...availableChores.map((chore) => _buildOneTimeCard(chore)),
        ],
        if (claimedChores.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader(
              'Đã có người nhận', Colors.blue, claimedChores.length),
          ...claimedChores.map((chore) => _buildOneTimeCard(chore)),
        ],
      ],
    );
  }

  // ============ CARD VIỆC XOAY VÒNG ============
  Widget _buildRecurringCard(Map<String, dynamic> chore) {
    final title = chore['title'] ?? 'Việc';
    final description = chore['description'] as String?;
    final frequency = chore['frequency'] ?? 'daily';
    final points = chore['points'] ?? 10;
    final currentAssigneeId = chore['currentAssigneeId'] ?? '';
    final currentAssigneeName = chore['currentAssigneeName'] ?? 'Chưa giao';
    final isMyTurn = currentAssigneeId == currentUserId;
    final lastCompletedDate = chore['lastCompletedDate'] as String?;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isCompletedToday = lastCompletedDate == todayStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompletedToday
              ? Colors.green
              : (isMyTurn ? AppColors.primary : Colors.grey.shade300),
          width: isCompletedToday || isMyTurn ? 2 : 1,
        ),
        boxShadow: isCompletedToday
            ? [
                BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]
            : (isMyTurn
                ? [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sync,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (description != null && description.isNotEmpty)
                            Text(description,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isCompletedToday)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Đã xong',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      )
                    else if (isMyTurn)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Lượt bạn',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lượt của: $currentAssigneeName',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    _buildTag(_getFrequencyText(frequency),
                        _getFrequencyColor(frequency)),
                    const SizedBox(width: 8),
                    _buildTag('$points điểm', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          if (isCompletedToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Đã hoàn thành hôm nay',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else if (isMyTurn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _completeRecurringChore(chore),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Hoàn thành',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  // ============ CARD VIỆC TỰ NHẬN ============
  Widget _buildOneTimeCard(Map<String, dynamic> chore) {
    final title = chore['title'] ?? 'Việc';
    final description = chore['description'] as String?;
    final points = chore['points'] ?? 10;
    final status = chore['status'] ?? 'available';
    final claimedByUserId = chore['claimedByUserId'];
    final claimedByUserName = chore['claimedByUserName'] ?? 'Unknown';
    final isClaimedByMe = claimedByUserId == currentUserId;
    final isAvailable = status == 'available';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimedByMe
              ? Colors.orange
              : (isAvailable ? Colors.green : Colors.blue),
          width: isClaimedByMe ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isAvailable ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isAvailable ? Icons.assignment : Icons.assignment_ind,
                        color: isAvailable ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (description != null && description.isNotEmpty)
                            Text(description,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    _buildTag('$points điểm', Colors.orange),
                  ],
                ),
                if (!isAvailable) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        isClaimedByMe
                            ? 'Bạn đã nhận việc này'
                            : 'Đã nhận bởi: $claimedByUserName',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isAvailable)
            _buildCardButton(
                onPressed: () => _claimChore(chore),
                label: 'Nhận việc này',
                color: Colors.green),
          if (isClaimedByMe)
            _buildCardButton(
                onPressed: () => _completeOneTimeChore(chore),
                label: 'Hoàn thành',
                color: AppColors.primary),
        ],
      ),
    );
  }

  // ============ HELPER WIDGETS ============
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCardButton(
      {required VoidCallback onPressed,
      required String label,
      required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddChoreDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm việc mới'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      default:
        return frequency;
    }
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'daily':
        return Colors.red;
      case 'weekly':
        return Colors.blue;
      case 'monthly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ============ ACTIONS ============
  Future<void> _claimChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    try {
      await FirestoreService.claimChore(
          choreId, currentUserId!, currentUserName!);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã nhận việc thành công')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _completeRecurringChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hoàn thành, cộng $points điểm')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _completeOneTimeChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hoàn thành, cộng $points điểm')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // ============ TAB BẢNG XẾP HẠNG ============
  Widget _buildLeaderboardTab() {
    if (leaderboard.isEmpty) {
      return _buildEmptyState('Chưa có dữ liệu xếp hạng', Icons.leaderboard,
          'Hoàn thành việc nhà để lên bảng xếp hạng');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final member = leaderboard[index];
        final name = member['name'] ?? 'User';
        final avatarUrl = (member['avatarUrl'] ?? '').toString();
        final avatarBase64 = (member['avatarBase64'] ?? '').toString();
        final points = (member['chorePoints'] as num?)?.toInt() ?? 0;
        final isTop3 = index < 3;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isTop3 ? Colors.amber.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isTop3 ? Border.all(color: Colors.amber, width: 2) : null,
            boxShadow: isTop3
                ? [
                    BoxShadow(
                        color: Colors.amber.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: index == 0
                      ? Colors.amber
                      : (index == 1
                          ? Colors.grey.shade400
                          : (index == 2
                              ? Colors.brown.shade300
                              : Colors.grey.shade200)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              UserAvatar(
                name: name.toString(),
                avatarUrl: avatarUrl,
                avatarBase64: avatarBase64,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Hạng ${index + 1}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('$points',
                        style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddChoreDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String choreType = 'recurring';
    String frequency = 'daily';
    int points = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thêm việc mới',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close)),
                    ]),
                const SizedBox(height: 16),
                // Chọn loại việc
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () => setModalState(() => choreType = 'recurring'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: choreType == 'recurring'
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: choreType == 'recurring'
                                ? AppColors.primary
                                : Colors.grey.shade300),
                      ),
                      child: Column(children: [
                        Icon(Icons.sync,
                            color: choreType == 'recurring'
                                ? AppColors.primary
                                : Colors.grey),
                        const SizedBox(height: 4),
                        Text('Xoay vòng',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: choreType == 'recurring'
                                    ? AppColors.primary
                                    : Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Luân phiên tự động',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                    onTap: () => setModalState(() => choreType = 'one-time'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: choreType == 'one-time'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: choreType == 'one-time'
                                ? Colors.orange
                                : Colors.grey.shade300),
                      ),
                      child: Column(children: [
                        Icon(Icons.assignment,
                            color: choreType == 'one-time'
                                ? Colors.orange
                                : Colors.grey),
                        const SizedBox(height: 4),
                        Text('Tự nhận',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: choreType == 'one-time'
                                    ? Colors.orange
                                    : Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Ai muốn làm thì nhận',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade600)),
                      ]),
                    ),
                  )),
                ]),
                const SizedBox(height: 16),
                TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                        labelText: 'Tên việc *',
                        hintText: 'VD: Quét nhà, Rửa bát...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(
                    controller: descController,
                    decoration: InputDecoration(
                        labelText: 'Mô tả (không bắt buộc)',
                        hintText: 'VD: Quét sạch sàn nhà',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 16),
                if (choreType == 'recurring') ...[
                  const Text('Tần suất:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      children: ['daily', 'weekly', 'monthly']
                          .map((f) => ChoiceChip(
                                label: Text(f == 'daily'
                                    ? 'Hàng ngày'
                                    : f == 'weekly'
                                        ? 'Hàng tuần'
                                        : 'Hàng tháng'),
                                selected: frequency == f,
                                selectedColor:
                                    AppColors.primary.withOpacity(0.2),
                                onSelected: (_) =>
                                    setModalState(() => frequency = f),
                              ))
                          .toList()),
                  const SizedBox(height: 16),
                ],
                const Text('Điểm thưởng:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20, 25, 30]
                        .map((p) => ChoiceChip(
                              label: Text('$p điểm'),
                              selected: points == p,
                              selectedColor: Colors.amber.withOpacity(0.3),
                              onSelected: (_) =>
                                  setModalState(() => points = p),
                            ))
                        .toList()),
                const SizedBox(height: 24),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vui lòng nhập tên việc')));
                          return;
                        }
                        try {
                          if (choreType == 'recurring') {
                            await FirestoreService.createRecurringChore(
                                houseId: currentHouseId!,
                                title: titleController.text,
                                description: descController.text,
                                frequency: frequency,
                                points: points);
                          } else {
                            await FirestoreService.createOneTimeChore(
                                houseId: currentHouseId!,
                                title: titleController.text,
                                description: descController.text,
                                points: points);
                          }
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Đã thêm việc ${choreType == 'recurring' ? 'xoay vòng' : 'tự nhận'}')));
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                        }
                      },
                      child: Text(
                          choreType == 'recurring'
                              ? 'Tạo việc xoay vòng'
                              : 'Tạo việc tự nhận',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ EXPENSES TAB - Hiển thị trực tiếp ============
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({super.key});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> expenses = [];
  double totalExpense = 0;
  String? currentUserId;
  String? currentHouseId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      currentUserId = await AuthService.getFirebaseUserId();
      currentHouseId = await AuthService.getFirebaseHouseId();

      if (currentHouseId == null || currentHouseId!.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final data = await FirestoreService.getExpensesByHouse(currentHouseId!);
      double total = 0;
      for (var e in data) {
        total += (e['amount'] ?? 0).toDouble();
      }

      setState(() {
        expenses = data;
        totalExpense = total;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Green Header - Y HỆT GIAO DIỆN GỐC (bỏ nút back)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Tổng chi tiêu',
                          amount: '${_formatMoney(totalExpense)} đ',
                          subtitle: 'Tháng này',
                          color: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.money_rounded,
                          title: 'Giao dịch',
                          amount: '${expenses.length}',
                          subtitle: 'Tổng số',
                          color: const Color(0xFFE8F5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black54,
                      labelStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Ai nợ ai'),
                        Tab(text: '📜 Lịch sử'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBalanceTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-expense');
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Thêm chi tiêu',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Colors.black26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Button to Balance Sheet
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/balance-sheet'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.account_balance, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảng Cân Đối Nợ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Xem ai nợ ai và thanh toán',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Khi bạn thêm chi tiêu và chia tiền, hệ thống sẽ tự động tính toán ai nợ ai.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (expenses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64, color: Colors.black26),
              SizedBox(height: 16),
              Text(
                'Chưa có giao dịch',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              SizedBox(height: 8),
              Text(
                'Thêm chi tiêu đầu tiên của bạn!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final title = expense['description'] ?? expense['title'] ?? 'Chi tiêu';
        final amount = (expense['amount'] ?? 0).toDouble();
        final paidBy = expense['paidByName'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('💳 $paidBy thanh toán',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Text(
                '-${_formatMoney(amount)}đ',
                style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============ BULLETIN TAB - Hiển thị trực tiếp + Thông tin phòng ============
class BulletinTab extends StatefulWidget {
  const BulletinTab({super.key});

  @override
  State<BulletinTab> createState() => _BulletinTabState();
}

class _BulletinTabState extends State<BulletinTab> {
  List<Map<String, dynamic>> notes = [];
  List<Map<String, dynamic>> shoppingItems = [];
  String? currentUserId;
  String? currentHouseId;
  bool isLoading = true;
  bool isAdmin = false;

  // Thông tin phòng
  String wifiName = '';
  String wifiPassword = '';
  String landlordPhone = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      currentUserId = await AuthService.getFirebaseUserId();
      currentHouseId = await AuthService.getFirebaseHouseId();

      if (currentHouseId == null || currentHouseId!.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final houseData = await FirestoreService.getHouseById(currentHouseId!);
      isAdmin = houseData?['ownerId'] == currentUserId;
      wifiName = houseData?['wifiName'] ?? '';
      wifiPassword = houseData?['wifiPassword'] ?? '';
      landlordPhone = houseData?['landlordPhone'] ?? '';

      final notesData = await FirestoreService.getNotesByHouse(currentHouseId!);
      final shoppingData =
          await FirestoreService.getShoppingItemsByHouse(currentHouseId!);

      setState(() {
        notes = notesData;
        shoppingItems = shoppingData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Đã sao chép!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2)),
    );
  }

  Future<void> _convertShoppingItemToExpense(Map<String, dynamic> item) async {
    final itemId = item['id'] as String?;
    final name = (item['name'] ?? 'Món đồ').toString();
    final amountCtrl = TextEditingController();
    String category = 'Mua sắm';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Chuyển sang Chi tiêu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Món: $name'),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  suffixText: 'đ',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: const [
                  DropdownMenuItem(value: 'Mua sắm', child: Text('Mua sắm')),
                  DropdownMenuItem(value: 'Ăn uống', child: Text('Ăn uống')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (v) =>
                    setModalState(() => category = v ?? 'Mua sắm'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tạo chi tiêu')),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không hợp lệ')),
      );
      return;
    }

    if (currentHouseId == null ||
        currentHouseId!.isEmpty ||
        currentUserId == null ||
        currentUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu thông tin người dùng/phòng')),
      );
      return;
    }

    try {
      final userName = await AuthService.getCurrentUserName() ?? 'Unknown';
      final members = await FirestoreService.getHouseMembers(currentHouseId!);
      if (members.isEmpty) {
        throw Exception('Phòng chưa có thành viên');
      }

      final splitAmount = amount / members.length;
      final splits = members
          .map((m) => {
                'userId': m['id'] as String,
                'userName': (m['name'] ?? 'Unknown').toString(),
                'amount': splitAmount,
              })
          .toList();

      await FirestoreService.createExpenseWithSplit(
        houseId: currentHouseId!,
        paidByUserId: currentUserId!,
        paidByName: userName,
        description: 'Mua sắm: $name',
        amount: amount,
        category: category,
        splitType: 'equal',
        splitWith: splits,
      );

      if (itemId != null) {
        await FirestoreService.updateShoppingItem(
            itemId, {'expenseLinked': true});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chuyển sang Chi tiêu')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Green Header - Y HỆT GIAO DIỆN GỐC (bỏ nút back)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isAdmin)
                        GestureDetector(
                          onTap: _showEditRoomInfoDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, color: Colors.black, size: 16),
                                SizedBox(width: 4),
                                Text('Sửa',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                      GestureDetector(
                        onTap: _loadData,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.refresh, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bảng tin chung',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thông tin & danh sách mua sắm',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  // Info Cards - WiFi (tên + mk) & SĐT Chủ nhà
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildWifiCard(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.phone_rounded,
                            title: 'Chủ nhà',
                            info: landlordPhone.isEmpty ? '---' : landlordPhone,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Ghi chú section
                        Row(
                          children: [
                            const Icon(Icons.push_pin_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text('Ghi chú',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${notes.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                    context, '/add-note');
                                if (result == true) _loadData();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (notes.isEmpty)
                          _buildEmptyState(
                              Icons.note_outlined, 'Chưa có ghi chú nào')
                        else
                          ...notes.map((note) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildNoteCard(note),
                              )),

                        const SizedBox(height: 24),

                        // Shopping list section
                        Row(
                          children: [
                            const Icon(Icons.shopping_cart_rounded, size: 20),
                            const SizedBox(width: 8),
                            const Text('Danh sách mua sắm',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${shoppingItems.where((i) => i['isPurchased'] != true).length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.pushNamed(
                                    context, '/add-shopping-item');
                                if (result == true) _loadData();
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (shoppingItems.isEmpty)
                          _buildEmptyState(Icons.shopping_cart_outlined,
                              'Chưa có món nào cần mua')
                        else
                          ...shoppingItems.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildShoppingItem(item),
                              )),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon, required String title, required String info}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54))),
              GestureDetector(
                onTap: () => _copyToClipboard(info),
                child: const Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(info,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 4),
          const Text(' ', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildWifiCard() {
    final name = wifiName.isEmpty ? '---' : wifiName;
    final pass = wifiPassword.isEmpty ? '---' : wifiPassword;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('WiFi',
                      style: TextStyle(fontSize: 12, color: Colors.black54))),
              GestureDetector(
                onTap: () => _copyToClipboard(pass),
                child: const Icon(Icons.copy_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 4),
          Text('MK: $pass',
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final title = note['title'] ?? 'Ghi chú';
    final content = note['content'] ?? '';
    final authorName = note['authorName'] ?? note['createdByName'] ?? 'Unknown';
    final isPinned = note['isPinned'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned ? Colors.orange : const Color(0xFFE0E0E0),
          width: isPinned ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinned) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.push_pin, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('Ghim',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(content,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(authorName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Món đồ';
    final isPurchased = item['isPurchased'] == true;
    final isExpenseLinked = item['expenseLinked'] == true;
    final itemId = item['id'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPurchased ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPurchased
                ? Colors.green.withOpacity(0.3)
                : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (itemId != null) {
                await FirestoreService.updateShoppingItem(
                    itemId, {'isPurchased': !isPurchased});
                _loadData();
              }
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPurchased ? Colors.green : Colors.transparent,
                border: Border.all(
                    color: isPurchased ? Colors.green : Colors.grey.shade400,
                    width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isPurchased
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: isPurchased ? TextDecoration.lineThrough : null,
                color: isPurchased ? Colors.grey : Colors.black,
              ),
            ),
          ),
          if (isPurchased) ...[
            if (!isExpenseLinked)
              IconButton(
                tooltip: 'Chuyển thành chi tiêu',
                onPressed: () => _convertShoppingItemToExpense(item),
                icon: const Icon(Icons.receipt_long,
                    color: Colors.orange, size: 20),
              )
            else
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ],
      ),
    );
  }

  void _showEditRoomInfoDialog() {
    final wifiNameCtrl = TextEditingController(text: wifiName);
    final wifiPassCtrl = TextEditingController(text: wifiPassword);
    final phoneCtrl = TextEditingController(text: landlordPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Sửa thông tin phòng',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              const SizedBox(height: 16),
              TextField(
                  controller: wifiNameCtrl,
                  decoration: InputDecoration(
                      labelText: 'Tên WiFi',
                      prefixIcon: const Icon(Icons.wifi),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(
                  controller: wifiPassCtrl,
                  decoration: InputDecoration(
                      labelText: 'Mật khẩu WiFi',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: 'SĐT Chủ trọ',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      try {
                        await FirestoreService.updateHouse(currentHouseId!, {
                          'wifiName': wifiNameCtrl.text,
                          'wifiPassword': wifiPassCtrl.text,
                          'landlordPhone': phoneCtrl.text,
                        });
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã cập nhật thông tin')));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    child: const Text('Lưu thông tin',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _userName = 'Người dùng';
  String? _userEmail = '';
  String? _avatarUrl;
  String? _avatarBase64;
  String? _userId;
  String? _houseCode = '';
  String? _houseName = '';
  int _chorePoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Lấy thông tin user hiện tại
  Future<void> _loadUserInfo() async {
    final sessionUser = await AuthService.getFirebaseUser();
    final name = await AuthService.getCurrentUserName();
    final email = await AuthService.getCurrentUserEmail();
    final firebaseUserId = await AuthService.getFirebaseUserId();
    final firebaseHouseId = await AuthService.getFirebaseHouseId();

    // Lấy thông tin phòng từ Firebase
    String? houseCode = '';
    String? houseName = '';
    int points = 0;
    String avatarUrl = (sessionUser?['avatarUrl'] ?? '').toString();
    String avatarBase64 = (sessionUser?['avatarBase64'] ?? '').toString();
    String resolvedName = name ?? 'Người dùng';
    String resolvedEmail = email ?? '';

    if (firebaseHouseId != null && firebaseHouseId.isNotEmpty) {
      try {
        final house = await FirestoreService.getHouseById(firebaseHouseId);
        if (house != null) {
          houseCode = house['joinCode'] ?? '';
          houseName = house['name'] ?? 'Chưa có phòng';
        }
      } catch (e) {
        print('Lỗi load house: $e');
      }
    }

    // Lấy điểm từ Firebase
    if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
      try {
        final userData = await FirestoreService.getUserById(firebaseUserId);
        points = (userData?['chorePoints'] as num?)?.toInt() ?? 0;
        resolvedName = (userData?['name'] ?? resolvedName).toString();
        resolvedEmail = (userData?['email'] ?? resolvedEmail).toString();
        avatarUrl = (userData?['avatarUrl'] ?? avatarUrl).toString();
        avatarBase64 = (userData?['avatarBase64'] ?? avatarBase64).toString();
      } catch (e) {
        print('Lỗi load user points: $e');
      }
    }

    setState(() {
      _userName = resolvedName;
      _userEmail = resolvedEmail;
      _avatarUrl = avatarUrl;
      _avatarBase64 = avatarBase64;
      _userId = firebaseUserId;
      _houseCode = houseCode ?? '';
      _houseName = houseName ?? '';
      _chorePoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Green Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Avatar
                _buildProfileAvatar(),
                const SizedBox(height: 16),
                Text(
                  _userName ?? 'Người dùng',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _userId != null
                        ? 'ID: ${_userId!.substring(0, _userId!.length > 8 ? 8 : _userId!.length)}...'
                        : 'ID: N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildMenuItem(
                icon: Icons.account_circle_outlined,
                title: 'Thông tin người dùng',
                subtitle: 'Cập nhật tên, email, ảnh đại diện, mật khẩu',
                onTap: () async {
                  final result =
                      await Navigator.pushNamed(context, '/profile-info');
                  if (result == true) {
                    _loadUserInfo();
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.home_outlined,
                title: 'Mã phòng của tôi',
                subtitle: _houseCode?.isNotEmpty == true
                    ? _houseCode!
                    : 'Chưa có phòng',
                onTap: _showHouseCodeDialog,
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.add_home_rounded,
                title: 'Vào phòng khác',
                subtitle: 'Nhập mã để join phòng',
                onTap: _showJoinHouseDialog,
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.star_rounded,
                title: 'Điểm của tôi',
                subtitle: '$_chorePoints điểm',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Bạn hiện có $_chorePoints điểm')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.leaderboard_rounded,
                title: 'Xếp hạng',
                subtitle: 'Bảng xếp hạng phòng',
                onTap: () {
                  Navigator.pushNamed(context, '/leaderboard');
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.settings_rounded,
                title: 'Cài đặt',
                subtitle: 'Cài đặt ứng dụng',
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.notifications_rounded,
                title: 'Thông báo',
                subtitle: 'Quản lý thông báo',
                onTap: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.help_rounded,
                title: 'Trợ giúp',
                subtitle: 'Câu hỏi thường gặp',
                onTap: _showHelpDialog,
              ),
              const SizedBox(height: 24),
              _buildMenuItem(
                icon: Icons.logout_rounded,
                title: 'Đăng xuất',
                subtitle: '',
                onTap: _handleLogout,
                isLogout: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Xử lý đăng xuất
  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trợ giúp nhanh'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Việc nhà: vào tab Công việc để nhận/hoàn thành.'),
            SizedBox(height: 6),
            Text('• Chi tiêu: thêm khoản mới ở tab Chi tiêu.'),
            SizedBox(height: 6),
            Text('• Bảng tin: lưu WiFi, SĐT và danh sách mua sắm.'),
            SizedBox(height: 6),
            Text('• Thông báo: xem nhắc việc và chi tiêu mới.'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
        ],
      ),
    );
  }

  // Dialog hiện mã phòng
  void _showHouseCodeDialog() {
    if (_houseCode?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa tham gia phòng nào'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mã phòng của tôi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Phòng: $_houseName'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: SelectableText(
                _houseCode!,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chia sẻ mã này với thành viên khác để họ join vào phòng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Dialog vào phòng khác
  void _showJoinHouseDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vào phòng khác'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập mã phòng để join:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'VD: ABC12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
              onChanged: (value) {
                codeController.text = value.toUpperCase();
                codeController.selection = TextSelection.fromPosition(
                  TextPosition(offset: value.length),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập mã phòng')),
                );
                return;
              }

              try {
                final userId = await AuthService.getFirebaseUserId();
                if (userId == null) throw Exception('User not found');

                final result = await FirestoreService.joinHouseByCode(
                  joinCode: codeController.text.trim().toUpperCase(),
                  userId: userId,
                );

                if (result['success'] == true) {
                  await AuthService.updateFirebaseHouseId(result['houseId']);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vào phòng thành công'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUserInfo(); // Reload thông tin phòng
                  }
                } else {
                  throw Exception(result['message'] ?? 'Vào phòng thất bại');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Vào phòng'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLogout ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isLogout ? const Color(0xFFE53935) : Colors.black26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isLogout ? const Color(0xFFE53935) : Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isLogout ? const Color(0xFFE53935) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: UserAvatar(
        name: _userName,
        avatarUrl: _avatarUrl,
        avatarBase64: _avatarBase64,
        radius: 38,
        backgroundColor: Colors.white,
        textColor: AppColors.primary,
      ),
    );
  }
}

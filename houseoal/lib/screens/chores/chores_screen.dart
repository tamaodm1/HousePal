import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ChoresScreen extends StatefulWidget {
  const ChoresScreen({super.key});

  @override
  State<ChoresScreen> createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data từ Firebase - 2 loại việc
  List<Map<String, dynamic>> recurringChores = []; // Việc xoay vòng
  List<Map<String, dynamic>> oneTimeChores = []; // Việc tự nhận
  List<Map<String, dynamic>> completedChores = []; // Việc đã xong

  String? currentUserId;
  String? currentUserName;
  String? currentHouseId;
  bool isAdmin = false; // Admin = người tạo phòng
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChores();
  }

  Future<void> _loadChores() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      currentUserId = await AuthService.getFirebaseUserId();
      currentHouseId = await AuthService.getFirebaseHouseId();

      if (currentHouseId == null || currentHouseId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Chưa tham gia phòng nào';
        });
        return;
      }

      // Lấy thông tin user để biết tên và check admin
      final userData = await FirestoreService.getUserById(currentUserId!);
      currentUserName = userData?['name'] ?? 'User';

      // Kiểm tra admin (owner của house)
      final houseData = await FirestoreService.getHouseById(currentHouseId!);
      isAdmin = houseData?['ownerId'] == currentUserId;

      // Load 2 loại chores
      final recurring =
          await FirestoreService.getRecurringChores(currentHouseId!);
      final oneTime = await FirestoreService.getOneTimeChores(currentHouseId!);
      final completed =
          await FirestoreService.getCompletedChores(currentHouseId!);

      setState(() {
        recurringChores = recurring;
        oneTimeChores = oneTime;
        completedChores = completed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Việc nhà',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/leaderboard');
            },
            icon: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.textWhite,
            ),
          ),
          IconButton(
            onPressed: _loadChores,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textWhite,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textWhite,
          indicatorWeight: 3,
          labelColor: AppColors.textWhite,
          unselectedLabelColor: AppColors.textWhite.withOpacity(0.6),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Xoay vòng'),
            Tab(text: 'Cần nhận'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: $errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadChores,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecurringTab(),
                    _buildOneTimeTab(),
                    _buildCompletedTab(),
                  ],
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddChoreDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: AppColors.textWhite),
              label: const Text(
                'Thêm việc',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null, // Chỉ Admin mới thêm được việc
    );
  }

  // ============ TAB XOAY VÒNG ============
  Widget _buildRecurringTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Việc xoay vòng',
          'Tự động luân phiên giữa các thành viên',
          Icons.sync,
          AppColors.primary,
          '${recurringChores.length} việc',
        ),
        const SizedBox(height: 16),
        if (recurringChores.isEmpty)
          _buildEmptyState('Chưa có việc xoay vòng nào', Icons.sync_disabled)
        else
          ...recurringChores.map((chore) => _buildRecurringCard(chore)),
      ],
    );
  }

  // ============ TAB CẦN NHẬN ============
  Widget _buildOneTimeTab() {
    // Chia thành 2 nhóm: chưa nhận và đã nhận
    final availableChores =
        oneTimeChores.where((c) => c['status'] == 'available').toList();
    final claimedChores =
        oneTimeChores.where((c) => c['status'] == 'claimed').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Việc cần nhận',
          'Ai muốn làm thì nhận việc',
          Icons.assignment,
          AppColors.warning,
          '${availableChores.length} chờ nhận',
        ),
        const SizedBox(height: 16),

        // Việc chờ nhận
        if (availableChores.isNotEmpty) ...[
          _buildSectionTitle('Chờ nhận', Colors.green),
          ...availableChores.map((chore) => _buildOneTimeCard(chore)),
        ],

        // Việc đã có người nhận
        if (claimedChores.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Đã có người nhận', Colors.blue),
          ...claimedChores.map((chore) => _buildOneTimeCard(chore)),
        ],

        if (oneTimeChores.isEmpty)
          _buildEmptyState('Chưa có việc cần nhận nào', Icons.inbox),
      ],
    );
  }

  // ============ TAB HOÀN THÀNH ============
  Widget _buildCompletedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Đã hoàn thành',
          'Việc đã được hoàn thành',
          Icons.done_all,
          AppColors.success,
          '${completedChores.length} việc',
        ),
        const SizedBox(height: 16),
        if (completedChores.isEmpty)
          _buildEmptyState(
              'Chưa có việc hoàn thành nào', Icons.check_circle_outline)
        else
          ...completedChores.map((chore) => _buildCompletedCard(chore)),
      ],
    );
  }

  // ============ CARD VIỆC XOAY VÒNG ============
  Widget _buildRecurringCard(Map<String, dynamic> chore) {
    final choreId = chore['id'] as String;
    final title = chore['title'] ?? 'Việc nhà';
    final description = chore['description'] as String?;
    final frequency = chore['frequency'] ?? 'daily';
    final points = chore['points'] ?? 10;
    final currentAssigneeId = chore['currentAssigneeId'] ?? '';
    final currentAssigneeName = chore['currentAssigneeName'] ?? 'Chưa giao';
    final isMyTurn = currentAssigneeId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppColors.primary.withOpacity(0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border:
            isMyTurn ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon loại việc
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sync,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + tag lượt của tôi
                      Row(
                        children: [
                          Expanded(
                            child: Text(title,
                                style: AppTextStyles.h4.copyWith(fontSize: 16)),
                          ),
                          if (isMyTurn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lượt bạn',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Người phụ trách hiện tại
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Lượt của: $currentAssigneeName',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag(_getFrequencyText(frequency), Icons.repeat,
                              AppColors.info),
                          const SizedBox(width: 8),
                          _buildTag('$points điểm', Icons.star_outline,
                              AppColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nút hoàn thành - chỉ hiện khi là lượt của mình
          if (isMyTurn)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _completeRecurringChore(chore),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Hoàn thành & Chuyển lượt'),
              ),
            ),
        ],
      ),
    );
  }

  // ============ CARD VIỆC TỰ NHẬN ============
  Widget _buildOneTimeCard(Map<String, dynamic> chore) {
    final choreId = chore['id'] as String;
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
        color: isClaimedByMe
            ? AppColors.warning.withOpacity(0.05)
            : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: isClaimedByMe
            ? Border.all(color: AppColors.warning, width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAvailable ? Icons.assignment : Icons.assignment_ind,
                    color: isAvailable ? Colors.green : Colors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.h4.copyWith(fontSize: 16)),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Status
                      if (!isAvailable)
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              isClaimedByMe
                                  ? 'Bạn đã nhận việc này'
                                  : 'Đã nhận bởi: $claimedByUserName',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag('Một lần', Icons.looks_one, AppColors.info),
                          const SizedBox(width: 8),
                          _buildTag('$points điểm', Icons.star_outline,
                              AppColors.warning),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Nút hành động
          if (isAvailable)
            _buildActionButton(
              onPressed: () => _claimChore(chore),
              icon: Icons.pan_tool,
              label: 'Nhận việc này',
              color: Colors.green,
            ),
          if (isClaimedByMe)
            _buildActionButton(
              onPressed: () => _completeOneTimeChore(chore),
              icon: Icons.check_circle,
              label: 'Hoàn thành',
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  // ============ CARD VIỆC ĐÃ HOÀN THÀNH ============
  Widget _buildCompletedCard(Map<String, dynamic> chore) {
    final title = chore['title'] ?? 'Việc';
    final points = chore['points'] ?? 10;
    final completedByUserId = chore['completedByUserId'];
    final claimedByUserName = chore['claimedByUserName'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.success, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hoàn thành bởi: $claimedByUserName (+$points điểm)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ ACTIONS ============

  Future<void> _claimChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    try {
      await FirestoreService.claimChore(
          choreId, currentUserId!, currentUserName!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã nhận việc thành công')),
      );
      _loadChores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _completeRecurringChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Hoàn thành, cộng $points điểm và đã chuyển lượt')),
      );
      _loadChores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _completeOneTimeChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hoàn thành, cộng $points điểm')),
      );
      _loadChores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String subtitle, IconData icon, Color color, String badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.h4.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(badge,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.bodyLarge
            .copyWith(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
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
        return AppColors.error;
      case 'weekly':
        return AppColors.warning;
      case 'monthly':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.date_range_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return '${diff.inDays} ngày trước';
    }
  }

  // ============ FORM THÊM VIỆC MỚI (2 LOẠI) ============
  void _showAddChoreDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String choreType = 'recurring'; // 'recurring' hoặc 'one-time'
    String selectedFrequency = 'daily';
    int points = 10;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Thêm việc mới', style: AppTextStyles.h3),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ========== CHỌN LOẠI VIỆC ==========
                      Text('Loại việc',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => choreType = 'recurring'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: choreType == 'recurring'
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: choreType == 'recurring'
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.sync,
                                        size: 32,
                                        color: choreType == 'recurring'
                                            ? AppColors.primary
                                            : Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('Xoay vòng',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: choreType == 'recurring'
                                                ? AppColors.primary
                                                : Colors.grey.shade600)),
                                    const SizedBox(height: 4),
                                    Text('Tự động luân phiên',
                                        style: AppTextStyles.caption.copyWith(
                                            color: Colors.grey.shade600),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => choreType = 'one-time'),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: choreType == 'one-time'
                                      ? AppColors.warning.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: choreType == 'one-time'
                                        ? AppColors.warning
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment,
                                        size: 32,
                                        color: choreType == 'one-time'
                                            ? AppColors.warning
                                            : Colors.grey),
                                    const SizedBox(height: 8),
                                    Text('Tự nhận',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: choreType == 'one-time'
                                                ? AppColors.warning
                                                : Colors.grey.shade600)),
                                    const SizedBox(height: 4),
                                    Text('Ai muốn làm thì nhận',
                                        style: AppTextStyles.caption.copyWith(
                                            color: Colors.grey.shade600),
                                        textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ========== TÊN VIỆC ==========
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên việc *',
                          hintText: choreType == 'recurring'
                              ? 'Ví dụ: Rửa bát, Đổ rác'
                              : 'Ví dụ: Mua đồ ăn, Dọn kho',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.cleaning_services),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== MÔ TẢ ==========
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mô tả (tùy chọn)',
                          hintText: 'Chi tiết công việc...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ========== TẦN SUẤT (chỉ cho recurring) ==========
                      if (choreType == 'recurring') ...[
                        Text('Tần suất',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFrequencyChip(
                                'Hàng ngày', 'daily', selectedFrequency, (f) {
                              setModalState(() => selectedFrequency = f);
                            }),
                            const SizedBox(width: 8),
                            _buildFrequencyChip(
                                'Hàng tuần', 'weekly', selectedFrequency, (f) {
                              setModalState(() => selectedFrequency = f);
                            }),
                            const SizedBox(width: 8),
                            _buildFrequencyChip(
                                'Hàng tháng', 'monthly', selectedFrequency,
                                (f) {
                              setModalState(() => selectedFrequency = f);
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ========== ĐIỂM THƯỞNG ==========
                      Text('Điểm thưởng',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [5, 10, 15, 20].map((p) {
                          final isSelected = points == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$p điểm'),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setModalState(() => points = p),
                              selectedColor: AppColors.primary,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // ========== BUTTON TẠO ==========
                      CustomButton(
                        text: choreType == 'recurring'
                            ? 'Tạo việc xoay vòng'
                            : 'Tạo việc tự nhận',
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vui lòng nhập tên việc')),
                            );
                            return;
                          }

                          try {
                            if (currentHouseId == null ||
                                currentHouseId!.isEmpty) {
                              throw Exception('Chưa tham gia phòng nào');
                            }

                            if (choreType == 'recurring') {
                              await FirestoreService.createRecurringChore(
                                houseId: currentHouseId!,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                frequency: selectedFrequency,
                                points: points,
                              );
                            } else {
                              await FirestoreService.createOneTimeChore(
                                houseId: currentHouseId!,
                                title: titleController.text.trim(),
                                description: descController.text.trim(),
                                points: points,
                              );
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(choreType == 'recurring'
                                        ? 'Đã tạo việc xoay vòng'
                                        : 'Đã tạo việc tự nhận')),
                              );
                              _loadChores();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Lỗi: ${e.toString().replaceAll('Exception: ', '')}')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFrequencyChip(
      String label, String value, String selected, Function(String) onTap) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _getFrequencyColor(value) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../../core/constants/colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/feed_service.dart';
import '../feed/feed_screen.dart';
import '../../models/post.dart';

// ─────────────────────────────────────────────
// DESIGN SYSTEM — Refined & Modern
// ─────────────────────────────────────────────
class _DS {
  // Primary palette — Deep teal + warm accents
  static const Color brand = Color(0xFF0EA47A);
  static const Color brandDark = Color(0xFF087D5E);
  static const Color brandLight = Color(0xFFE6F7F1);
  static const Color surface = Color(0xFFF5F6F8);
  static const Color card = Colors.white;
  static const Color onCard = Color(0xFF1A1D26);
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF7C8293);
  static const Color subtle = Color(0xFF7C8293);
  static const Color border = Color(0xFFEBEDF2);
  static const Color divider = Color(0xFFF0F1F4);

  // Semantic colors
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF0A30A);
  static const Color warningBg = Color(0xFFFFF8E1);
  static const Color success = Color(0xFF30A46C);
  static const Color info = Color(0xFF0091FF);
  static const Color purple = Color(0xFF7C5CFC);
  static const Color pink = Color(0xFFE93D82);

  // Dark card colors (for feature cards)
  static const Color darkCard = Color(0xFF1E2230);
  static const Color darkCardLight = Color(0xFF262B3A);

  // Gradient
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0EA47A), Color(0xFF0B8A68)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0FB882), Color(0xFF0A9467)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  // Radii
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;
  static const double r28 = 28;

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.45,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.2,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    letterSpacing: 0.3,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF1A1D26).withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF1A1D26).withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFF1A1D26).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF1A1D26).withOpacity(0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> brandShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> colorShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

// ─────────────────────────────────────────────
// HOME SCREEN — Bottom Nav
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _DS.surface,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            key: ValueKey<int>(_currentIndex),
            index: _currentIndex,
            children: const [
              DashboardTab(),
              ChoresTab(),
              ExpensesTab(),
              BulletinTab(),
              ProfileTab(),
            ],
          ),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
    (Icons.checklist_rounded, Icons.checklist_outlined, 'Công việc'),
    (
      Icons.account_balance_wallet_rounded,
      Icons.account_balance_wallet_outlined,
      'Chi tiêu'
    ),
    (Icons.newspaper_rounded, Icons.newspaper_outlined, 'Bảng tin'),
    (Icons.person_rounded, Icons.person_outlined, 'Cá nhân'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = currentIndex == i;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    splashColor: _DS.brand.withOpacity(0.25),
                    highlightColor: _DS.brand.withOpacity(0.14),
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: selected ? 50 : 42,
                          height: selected ? 50 : 42,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0FC78D),
                                      Color(0xFF0A9467)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: selected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? _DS.brandDark
                                  : _DS.subtle.withOpacity(0.2),
                              width: selected ? 1.0 : 0.5,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: _DS.brand.withOpacity(0.22),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            selected ? item.$1 : item.$2,
                            size: selected ? 24 : 20,
                            color: selected ? Colors.white : _DS.brandDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? _DS.brandDark
                                : _DS.subtle.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedOpacity(
                          opacity: selected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: 18,
                            height: 3,
                            decoration: BoxDecoration(
                              color: selected ? _DS.brand : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED HEADER — Cleaner gradient
// ─────────────────────────────────────────────
class _GreenHeader extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const _GreenHeader({required this.child, this.bottomPadding = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: _DS.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PILL / BADGE — Refined
// ─────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const _Pill(this.label,
      {required this.color, this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: filled ? Colors.white : color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DASHBOARD TAB — Redesigned with Beautiful Tabs
// ─────────────────────────────────────────────
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
  bool _isAdmin = false;
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
  int _todayChoreTotal = 0;
  List<Map<String, dynamic>> _todayChores = [];
  List<Map<String, dynamic>> _upcomingChores = [];
  List<Map<String, dynamic>> _topMembers = [];

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
        final houseData = await FirestoreService.getHouseById(houseId);
        final isAdmin = houseData?['ownerId'] == userId;
        final chores = await FirestoreService.getChoresByHouse(houseId);
        final notes = await FirestoreService.getNotesByHouse(houseId);
        final expenses = await FirestoreService.getExpensesByHouse(houseId);
        final shoppingItems =
            await FirestoreService.getShoppingItemsByHouse(houseId);
        final members = await FirestoreService.getHouseMembers(houseId);

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
        members.sort((a, b) => ((b['chorePoints'] as num?) ?? 0)
            .compareTo((a['chorePoints'] as num?) ?? 0));

        final upcomingChores = [...chores]..sort((a, b) {
            final byPriority = _getDashboardChorePriority(a)
                .compareTo(_getDashboardChorePriority(b));
            if (byPriority != 0) return byPriority;
            final aPoints = (a['points'] as num?)?.toInt() ?? 0;
            final bPoints = (b['points'] as num?)?.toInt() ?? 0;
            return bPoints.compareTo(aPoints);
          });

        final todayChoreCandidates = chores.where((chore) {
          return _isCompletedToday(chore) || _isMyPendingChore(chore);
        }).toList();

        setState(() {
          _isAdmin = isAdmin;
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
          _todayChoreTotal = todayChoreCandidates.length;
          _todayChores = todayChoreCandidates.take(4).toList();
          _upcomingChores = upcomingChores.take(6).toList();
          _topMembers = members.take(3).toList();
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

  Future<void> _deleteChore(Map<String, dynamic> chore) async {
    if (!_isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Chỉ quản lý nhà mới có quyền xóa việc')),
        );
      }
      return;
    }

    final choreId = (chore['id'] ?? '').toString();
    if (choreId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa việc này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa',
                  style: TextStyle(color: Color(0xFFE5484D)))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.deleteChore(choreId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa việc thành công')));
        _loadData();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GreenHeader(
          bottomPadding: 24,
          child: Column(
            children: [
              // Top row: avatar + greeting + bell
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào,',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _userName!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 21),
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _DS.danger,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0FB882), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  _unreadNotificationCount > 9
                                      ? '9+'
                                      : '$_unreadNotificationCount',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Points banner — clean green style
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Điểm thành viên',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400)),
                          const SizedBox(height: 2),
                          Text(
                            '$_chorePoints điểm',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5),
                          ),
                        ],
                      ),
                    ),
                    // Mini stats
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _miniStatInline('$_choreCount', 'việc'),
                          Container(
                            width: 1,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: Colors.white.withOpacity(0.15),
                          ),
                          _miniStatInline('$_memberCount', 'người'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Quick Access Feature Tabs ──
                _buildFeatureTabs(),
                const SizedBox(height: 20),

                // ── Việc nhà hôm nay (xoay vòng) ──
                _buildTodayChoreWheelCard(),
                const SizedBox(height: 20),

                // ── Tin tức ngắn ──
                _buildUpcomingSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStatInline(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style:
                TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.55))),
      ],
    );
  }

  // ─── FEATURE TABS — All brand green, white icons ───
  Widget _buildFeatureTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _DS.brand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Quản lý',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _DS.textPrimary)),
          ],
        ),
        const SizedBox(height: 14),

        // Row 1: Two large feature cards — both green tones
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                title: 'Chi tiêu tháng này',
                value: '${_formatCompactMoney(_monthlyExpenseTotal)}đ',
                subtitle: '$_expenseCount khoản chi',
                icon: Icons.account_balance_wallet_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA47A), Color(0xFF14C99A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                iconBgColor: Colors.white.withOpacity(0.2),
                onTap: () => Navigator.pushNamed(context, '/expenses'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeatureCard(
                title: 'Việc nhà hôm nay',
                value: '$_myTurnChoreCount',
                subtitle: 'cần hoàn thành',
                icon: Icons.checklist_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF087D5E), Color(0xFF0EA47A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                iconBgColor: Colors.white.withOpacity(0.2),
                onTap: () => Navigator.pushNamed(context, '/chores'),
                badge: _myTurnChoreCount > 0 ? 'Tới lượt bạn' : null,
                badgeColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Three smaller feature cards — all green
        Row(
          children: [
            Expanded(
              child: _MiniFeatureCard(
                title: 'Mua sắm',
                value: '$_pendingShoppingCount',
                icon: Icons.shopping_bag_rounded,
                color: _DS.brand,
                onTap: () => Navigator.pushNamed(context, '/bulletin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniFeatureCard(
                title: 'Thông báo',
                value: '$_unreadNotificationCount',
                icon: Icons.notifications_rounded,
                color: _DS.brand,
                hasIndicator: _unreadNotificationCount > 0,
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniFeatureCard(
                title: 'Ghi chú',
                value: '$_noteCount',
                icon: Icons.push_pin_rounded,
                color: _DS.brand,
                onTap: () => Navigator.pushNamed(context, '/bulletin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTodayChoreWheelCard() {
    final progress = _todayChoreTotal == 0
        ? 0.0
        : (_completedTodayCount / _todayChoreTotal).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('VIỆC NHÀ HÔM NAY (Xoay vòng)',
                    style: _DS.heading2
                        .copyWith(color: _DS.textPrimary, fontSize: 16)),
              ),
              Icon(Icons.loop, color: _DS.brand, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  color: _DS.brandLight,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _DS.cardShadow,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _DS.brand,
                          shape: BoxShape.circle,
                          boxShadow: _DS.brandShadow(_DS.brand),
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(_todayChoreTotal == 0 ? 0 : (progress * 100).round())}%',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _DS.brand),
                      ),
                      const SizedBox(height: 2),
                      Text('Hoàn thành',
                          style: _DS.bodySmall.copyWith(
                              color: _DS.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_completedTodayCount / $_todayChoreTotal việc',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (_todayChores.isEmpty)
                      Text('Không có việc hôm nay', style: _DS.body)
                    else
                      ..._todayChores
                          .take(2)
                          .map((chore) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _isCompletedToday(chore)
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      size: 16,
                                      color: _isCompletedToday(chore)
                                          ? _DS.success
                                          : _DS.warning,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        (chore['title'] ?? 'Công việc')
                                            .toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteChore(chore),
                                      child: Icon(Icons.delete_outline,
                                          size: 18, color: _DS.danger),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    const SizedBox(height: 10),
                    if (_topMembers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: _DS.brandLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('BXH thành viên',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _DS.brandDark)),
                            const SizedBox(height: 8),
                            ..._topMembers.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final member = entry.value;
                              final name =
                                  (member['name'] ?? 'Không tên').toString();
                              final points =
                                  (member['chorePoints'] ?? 0).toString();
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: idx == 0
                                            ? _DS.brand
                                            : idx == 1
                                                ? _DS.brandDark
                                                : _DS.success,
                                      ),
                                      child: Center(
                                        child: Text('${idx + 1}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    UserAvatar(
                                      name: name,
                                      avatarUrl: (member['avatarUrl'] ?? '')
                                          .toString(),
                                      avatarBase64:
                                          (member['avatarBase64'] ?? '')
                                              .toString(),
                                      radius: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(name,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    Text('$points đ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _DS.textSecondary,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      )
                    else
                      Text('Chưa có bảng xếp hạng',
                          style:
                              _DS.caption.copyWith(color: _DS.textSecondary)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (_todayChoreTotal > 0 && _completedTodayCount < _todayChoreTotal)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _DS.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pushNamed(context, '/chores'),
              child: const Text('Hoàn thành',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _DS.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('Đã hoàn thành',
                    style: TextStyle(
                        color: _DS.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: _DS.brand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Tin tức mới',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: _DS.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/feed'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _DS.brand.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Xem thêm',
                        style: TextStyle(
                            fontSize: 12,
                            color: _DS.brand,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: _DS.brand),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Post>>(
          stream: FeedService.getGlobalFeedStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data ?? [];
            if (posts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _DS.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _DS.cardShadow,
                ),
                child: Text('Chưa có tin tức nào.', style: _DS.body),
              );
            }

            return Column(
              children: posts.take(2).map((post) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DS.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _DS.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        name: post.authorName,
                        avatarUrl: post.avatarUrl,
                        avatarBase64: post.avatarBase64,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(post.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: _DS.bodySmall),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(post.houseName,
                                    style: _DS.caption
                                        .copyWith(color: _DS.textSecondary)),
                                Text('${post.likes} ❤️  ${post.comments} 💬',
                                    style: _DS.caption
                                        .copyWith(color: _DS.textSecondary)),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }

  Widget _buildChoreGrid() {
    final List<Widget> rows = [];
    for (int i = 0; i < _upcomingChores.length; i += 2) {
      final left = _upcomingChores[i];
      final right =
          (i + 1 < _upcomingChores.length) ? _upcomingChores[i + 1] : null;
      rows.add(
        Padding(
          padding:
              EdgeInsets.only(bottom: i + 2 < _upcomingChores.length ? 10 : 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ChoreGridCard(
                    chore: left,
                    currentUserId: _currentUserId,
                    isMyPending: _isMyPendingChore(left),
                    isCompletedToday: _isCompletedToday(left),
                    onDelete: _deleteChore,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: right != null
                      ? _ChoreGridCard(
                          chore: right,
                          currentUserId: _currentUserId,
                          isMyPending: _isMyPendingChore(right),
                          isCompletedToday: _isCompletedToday(right),
                          onDelete: _deleteChore,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildAvatar() {
    final avatarUrl = (_avatarUrl ?? '').trim();
    final avatarBase64 = (_avatarBase64 ?? '').trim();
    final hasUrl =
        avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');
    ImageProvider? ip;
    if (avatarBase64.isNotEmpty) {
      try {
        ip = MemoryImage(base64Decode(avatarBase64));
      } catch (_) {}
    }
    if (ip == null && hasUrl) ip = NetworkImage(avatarUrl);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: ip != null
            ? Image(
                image: ip,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initAvatar())
            : _initAvatar(),
      ),
    );
  }

  Widget _initAvatar() => Container(
        color: Colors.white,
        child: Center(
          child: Text(
            (_userName?.isNotEmpty ?? false)
                ? _userName![0].toUpperCase()
                : 'U',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: _DS.brand),
          ),
        ),
      );

  double _calculateMonthlyExpenseTotal(List<Map<String, dynamic>> expenses) {
    final now = DateTime.now();
    return expenses.where((e) {
      final createdAt = e['createdAt'];
      if (createdAt is! DateTime) return false;
      return createdAt.year == now.year && createdAt.month == now.month;
    }).fold(0.0, (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0));
  }

  String _formatCompactMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  bool _isCompletedToday(Map<String, dynamic> chore) {
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') return chore['status'] == 'completed';
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return chore['lastCompletedDate'] == todayStr;
  }

  bool _isMyPendingChore(Map<String, dynamic> chore) {
    if (_currentUserId == null || _currentUserId!.isEmpty) return false;
    if (_isCompletedToday(chore)) return false;
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime')
      return chore['status'] == 'claimed' &&
          chore['assignedToUserId'] == _currentUserId;
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
}

// ─────────────────────────────────────────────
// Feature Card — Large green gradient cards
// ─────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color iconBgColor;
  final VoidCallback? onTap;
  final String? badge;
  final Color? badgeColor;

  const _FeatureCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.iconBgColor,
    this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 21),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? Colors.white).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: gradient.colors.first)),
                  )
                else
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w400)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mini Feature Card — Smaller (3 in a row) with solid icon bg
// ─────────────────────────────────────────────
class _MiniFeatureCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasIndicator;
  final VoidCallback? onTap;

  const _MiniFeatureCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.hasIndicator = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _DS.cardShadow,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                if (hasIndicator)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _DS.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _DS.onCard,
                    letterSpacing: -0.3)),
            const SizedBox(height: 2),
            Text(title,
                style: TextStyle(
                    fontSize: 11,
                    color: _DS.subtle.withOpacity(0.7),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Quick Stat Chip — Horizontal inline chip
// ─────────────────────────────────────────────
class _QuickStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlighted;

  const _QuickStatChip({
    required this.icon,
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? _DS.brand : _DS.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: highlighted
                  ? Colors.white.withOpacity(0.2)
                  : _DS.brand.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 14, color: highlighted ? Colors.white : _DS.brand),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: highlighted ? Colors.white : _DS.onCard)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: highlighted
                          ? Colors.white.withOpacity(0.7)
                          : _DS.subtle.withOpacity(0.65),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat Chip
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _DS.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _DS.onCard)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: _DS.subtle)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Chore Grid Card — 2-column grid style
// ─────────────────────────────────────────────
class _ChoreGridCard extends StatelessWidget {
  final Map<String, dynamic> chore;
  final String? currentUserId;
  final bool isMyPending;
  final bool isCompletedToday;
  final Future<void> Function(Map<String, dynamic> chore)? onDelete;

  const _ChoreGridCard({
    required this.chore,
    this.currentUserId,
    required this.isMyPending,
    required this.isCompletedToday,
    this.onDelete,
  });

  String get _statusLine {
    final type = chore['type'] ?? 'recurring';
    final freq = _freqText;

    if (isCompletedToday) return '$freq | Đã xong';

    if (type == 'oneTime') {
      final status = chore['status'] ?? 'available';
      if (status == 'claimed') {
        return chore['assignedToUserId'] == currentUserId
            ? 'Bạn đang nhận việc này'
            : '${chore['assignedToUserName'] ?? 'Ai đó'} đang làm';
      }
      return 'Chưa ai nhận | Tự nhận';
    }

    final assignee = chore['currentAssigneeName'] ?? 'Chưa giao';
    if (chore['currentAssigneeId'] == currentUserId)
      return '$freq | Tới lượt bạn';
    return 'Tới lượt: $assignee | $freq';
  }

  String get _freqText {
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

  String get _badge {
    if (isCompletedToday) return 'Xong';
    if (isMyPending) return 'Tới lượt';
    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime' && chore['status'] == 'available') return 'Nhận việc';
    return 'Sắp tới';
  }

  // Smart icon based on chore title keywords
  IconData get _smartIcon {
    final title = (chore['title'] ?? '').toString().toLowerCase();
    if (title.contains('rác') || title.contains('đổ'))
      return Icons.delete_outline_rounded;
    if (title.contains('rửa') ||
        title.contains('bát') ||
        title.contains('chén')) return Icons.wash_rounded;
    if (title.contains('quét') ||
        title.contains('lau') ||
        title.contains('sàn')) return Icons.cleaning_services_rounded;
    if (title.contains('giặt') ||
        title.contains('quần') ||
        title.contains('áo') ||
        title.contains('đồ')) return Icons.local_laundry_service_rounded;
    if (title.contains('nấu') ||
        title.contains('cơm') ||
        title.contains('ăn') ||
        title.contains('bếp')) return Icons.restaurant_rounded;
    if (title.contains('cửa') || title.contains('kính'))
      return Icons.window_rounded;
    if (title.contains('cây') ||
        title.contains('tưới') ||
        title.contains('hoa')) return Icons.yard_rounded;
    if (title.contains('tủ') || title.contains('lạnh') || title.contains('dọn'))
      return Icons.kitchen_rounded;
    if (title.contains('mua') || title.contains('sắm') || title.contains('chợ'))
      return Icons.shopping_cart_rounded;
    if (title.contains('phòng') || title.contains('ngủ'))
      return Icons.bed_rounded;
    if (title.contains('toilet') ||
        title.contains('vệ sinh') ||
        title.contains('wc')) return Icons.bathroom_rounded;
    if (title.contains('xe') || title.contains('rửa xe'))
      return Icons.directions_car_rounded;

    final type = chore['type'] ?? 'recurring';
    if (type == 'oneTime') return Icons.assignment_rounded;
    return Icons.autorenew_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final title = chore['title'] ?? 'Công việc';
    final points = (chore['points'] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMyPending ? _DS.brand.withOpacity(0.04) : _DS.card,
        borderRadius: BorderRadius.circular(16),
        border: isMyPending
            ? Border.all(color: _DS.brand.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1D26).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: icon + info + delete button
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompletedToday
                      ? _DS.brand.withOpacity(0.08)
                      : _DS.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCompletedToday ? Icons.check_circle_rounded : _smartIcon,
                  color: isCompletedToday ? _DS.brand : Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _DS.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline_rounded,
                    size: 14, color: _DS.subtle.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete == null
                    ? null
                    : () async {
                        await onDelete!(chore);
                      },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _DS.danger.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 14, color: _DS.danger),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isCompletedToday ? _DS.subtle : _DS.textPrimary,
              letterSpacing: -0.2,
              decoration: isCompletedToday ? TextDecoration.lineThrough : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Points
          Text(
            '$points điểm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _DS.brand.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 10),

          // Status line
          Text(
            _statusLine,
            style: TextStyle(
              fontSize: 11,
              color: _DS.subtle.withOpacity(0.65),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: _DS.textPrimary),
      );
}

// ─────────────────────────────────────────────
// CHORES TAB — Redesigned
// ─────────────────────────────────────────────
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
      backgroundColor: _DS.surface,
      body: Column(
        children: [
          _GreenHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Việc nhà',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          SizedBox(height: 2),
                          Text('Quản lý & xoay vòng công việc',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: _DS.brand,
                    unselectedLabelColor: Colors.white.withOpacity(0.85),
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400),
                    dividerColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: const [
                      Tab(text: 'Xoay vòng', height: 34),
                      Tab(text: 'Tự nhận', height: 34),
                      Tab(text: 'Xếp hạng', height: 34),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: _DS.brand, strokeWidth: 2.5))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecurringTab(),
                      _buildOneTimeTab(),
                      _buildLeaderboardTab()
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddChoreDialog,
              backgroundColor: _DS.brand,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child:
                  const Icon(Icons.add_rounded, size: 26, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildRecurringTab() {
    if (recurringChores.isEmpty)
      return _emptyState('Chưa có việc xoay vòng', Icons.sync_disabled_rounded,
          'Việc xoay vòng tự động luân phiên giữa các thành viên');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: recurringChores.map(_buildRecurringCard).toList(),
    );
  }

  Widget _buildOneTimeTab() {
    final available =
        oneTimeChores.where((c) => c['status'] == 'available').toList();
    final claimed =
        oneTimeChores.where((c) => c['status'] == 'claimed').toList();
    if (oneTimeChores.isEmpty)
      return _emptyState('Chưa có việc cần nhận', Icons.inbox_rounded,
          'Ai rảnh thì nhận việc và kiếm điểm');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        if (available.isNotEmpty) ...[
          _sectionHeader('Đang chờ nhận', _DS.success, available.length),
          ...available.map(_buildOneTimeCard),
        ],
        if (claimed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionHeader('Đã có người nhận', _DS.info, claimed.length),
          ...claimed.map(_buildOneTimeCard),
        ],
      ],
    );
  }

  Widget _buildRecurringCard(Map<String, dynamic> chore) {
    final title = chore['title'] ?? 'Việc';
    final description = chore['description'] as String?;
    final frequency = chore['frequency'] ?? 'daily';
    final points = chore['points'] ?? 10;
    final currentAssigneeId = chore['currentAssigneeId'] ?? '';
    final currentAssigneeName = chore['currentAssigneeName'] ?? 'Chưa giao';
    final isMyTurn = currentAssigneeId == currentUserId;
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final isCompletedToday = chore['lastCompletedDate'] == todayStr;

    final accentColor =
        isCompletedToday ? _DS.success : (isMyTurn ? _DS.brand : _DS.subtle);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(_DS.r16),
        border: (isCompletedToday || isMyTurn)
            ? Border.all(color: accentColor.withOpacity(0.35), width: 1)
            : null,
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompletedToday
                        ? Icons.check_circle_outline_rounded
                        : Icons.autorenew_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _DS.heading3),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(description, style: _DS.bodySmall),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: _DS.subtle),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text('Lượt của: $currentAssigneeName',
                                  style: _DS.caption)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Pill(_getFrequencyText(frequency),
                              color: _getFrequencyColor(frequency)),
                          _Pill('$points đ', color: _DS.brand),
                          if (isCompletedToday)
                            _Pill('Đã xong', color: _DS.success, filled: true),
                          if (isMyTurn && !isCompletedToday)
                            _Pill('Lượt bạn', color: _DS.brand, filled: true),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  GestureDetector(
                    onTap: () => _deleteChore(chore),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _DS.danger.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 14, color: _DS.danger),
                    ),
                  ),
              ],
            ),
          ),
          if (isCompletedToday)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _DS.success.withOpacity(0.06),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: _DS.success, size: 16),
                  const SizedBox(width: 6),
                  Text('Đã hoàn thành hôm nay',
                      style: TextStyle(
                          color: _DS.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            )
          else if (isMyTurn)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => _completeRecurringChore(chore),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _DS.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Đánh dấu hoàn thành',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOneTimeCard(Map<String, dynamic> chore) {
    final title = chore['title'] ?? 'Việc';
    final description = chore['description'] as String?;
    final points = chore['points'] ?? 10;
    final status = chore['status'] ?? 'available';
    final claimedByUserId = chore['claimedByUserId'];
    final claimedByUserName = chore['claimedByUserName'] ?? 'Unknown';
    final isClaimedByMe = claimedByUserId == currentUserId;
    final isAvailable = status == 'available';
    final accentColor =
        isClaimedByMe ? _DS.warning : (isAvailable ? _DS.success : _DS.info);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(_DS.r16),
        border: isClaimedByMe
            ? Border.all(color: _DS.warning.withOpacity(0.35), width: 1)
            : null,
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      isAvailable
                          ? Icons.volunteer_activism_rounded
                          : Icons.person_pin_circle_rounded,
                      color: accentColor,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _DS.heading3),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(description, style: _DS.bodySmall),
                      ],
                      const SizedBox(height: 8),
                      if (!isAvailable)
                        Row(children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: _DS.subtle),
                          const SizedBox(width: 4),
                          Text(
                            isClaimedByMe
                                ? 'Bạn đã nhận việc này'
                                : 'Đã nhận bởi: $claimedByUserName',
                            style: TextStyle(
                                fontSize: 12,
                                color: isClaimedByMe ? _DS.warning : _DS.info,
                                fontWeight: FontWeight.w600),
                          ),
                        ]),
                      const SizedBox(height: 6),
                      _Pill('$points đ', color: _DS.brand),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteChore(chore),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _DS.danger.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 14, color: _DS.danger),
                  ),
                ),
              ],
            ),
          ),
          if (isAvailable)
            _cardButton(
                onPressed: () => _claimChore(chore),
                label: 'Nhận việc này',
                color: _DS.success),
          if (isClaimedByMe)
            _cardButton(
                onPressed: () => _completeOneTimeChore(chore),
                label: 'Hoàn thành',
                color: _DS.brand),
        ],
      ),
    );
  }

  Widget _cardButton(
      {required VoidCallback onPressed,
      required String label,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            elevation: 0,
          ),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: _DS.heading3),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6)),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _DS.brand.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 30, color: _DS.brand.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text(title, style: _DS.heading3),
            const SizedBox(height: 6),
            Text(subtitle, style: _DS.body, textAlign: TextAlign.center),
            if (isAdmin) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showAddChoreDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm việc mới',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (leaderboard.isEmpty)
      return _emptyState('Chưa có dữ liệu xếp hạng', Icons.leaderboard_rounded,
          'Hoàn thành việc nhà để lên bảng xếp hạng');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final member = leaderboard[index];
        final name = member['name'] ?? 'User';
        final avatarUrl = (member['avatarUrl'] ?? '').toString();
        final avatarBase64 = (member['avatarBase64'] ?? '').toString();
        final points = (member['chorePoints'] as num?)?.toInt() ?? 0;
        final rankColors = [
          const Color(0xFFE8A900),
          const Color(0xFF9E9E9E),
          const Color(0xFFCD7F32)
        ];
        final rankColor = index < 3 ? rankColors[index] : _DS.subtle;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(_DS.r14),
            border: index < 3
                ? Border.all(color: rankColor.withOpacity(0.3), width: 1)
                : null,
            boxShadow: _DS.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: index < 3 ? rankColor.withOpacity(0.12) : _DS.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                    child: Text(
                  '${index + 1}',
                  style: TextStyle(
                      color: index < 3 ? rankColor : _DS.subtle,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                )),
              ),
              const SizedBox(width: 10),
              UserAvatar(
                  name: name.toString(),
                  avatarUrl: avatarUrl,
                  avatarBase64: avatarBase64,
                  radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: _DS.heading3),
                    Text('Hạng ${index + 1}', style: _DS.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _DS.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: _DS.warning, size: 14),
                  const SizedBox(width: 3),
                  Text('$points',
                      style: const TextStyle(
                          color: _DS.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── ACTIONS ───
  Future<void> _claimChore(Map<String, dynamic> chore) async {
    try {
      await FirestoreService.claimChore(
          chore['id'], currentUserId!, currentUserName!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã nhận việc thành công')));
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteChore(Map<String, dynamic> chore) async {
    final choreId = (chore['id'] ?? '').toString();
    if (choreId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa việc này không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa',
                  style: TextStyle(color: Color(0xFFE5484D)))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirestoreService.deleteChore(choreId);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa việc thành công')));
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể xóa: $e')));
    }
  }

  Future<void> _completeRecurringChore(Map<String, dynamic> chore) async {
    try {
      await FirestoreService.completeChore(chore['id'], currentUserId!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hoàn thành, cộng ${chore['points'] ?? 10} điểm')));
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _completeOneTimeChore(Map<String, dynamic> chore) async {
    try {
      await FirestoreService.completeChore(chore['id'], currentUserId!);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Hoàn thành, cộng ${chore['points'] ?? 10} điểm')));
      _loadData();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  String _getFrequencyText(String f) => f == 'daily'
      ? 'Hàng ngày'
      : f == 'weekly'
          ? 'Hàng tuần'
          : f == 'monthly'
              ? 'Hàng tháng'
              : f;
  Color _getFrequencyColor(String f) => f == 'daily'
      ? _DS.danger
      : f == 'weekly'
          ? _DS.info
          : f == 'monthly'
              ? _DS.purple
              : _DS.subtle;

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
        builder: (context, setModal) => Container(
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
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: _DS.surface,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: _DS.subtle),
                        ),
                      ),
                    ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: _typeChip(
                          'recurring',
                          'Xoay vòng',
                          Icons.sync_rounded,
                          choreType,
                          (v) => setModal(() => choreType = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _typeChip(
                          'one-time',
                          'Tự nhận',
                          Icons.assignment_rounded,
                          choreType,
                          (v) => setModal(() => choreType = v))),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Tên việc *',
                    labelStyle: _DS.bodySmall,
                    hintText: 'VD: Quét nhà, Rửa bát...',
                    hintStyle: TextStyle(color: _DS.subtle.withOpacity(0.5)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _DS.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _DS.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _DS.brand, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Mô tả (không bắt buộc)',
                    labelStyle: _DS.bodySmall,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _DS.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _DS.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _DS.brand, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),
                if (choreType == 'recurring') ...[
                  Text('Tần suất', style: _DS.label),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      children: ['daily', 'weekly', 'monthly']
                          .map((f) => ChoiceChip(
                                label: Text(_getFrequencyText(f)),
                                selected: frequency == f,
                                selectedColor: _DS.brand.withOpacity(0.15),
                                onSelected: (_) =>
                                    setModal(() => frequency = f),
                                labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: frequency == f
                                        ? FontWeight.w600
                                        : FontWeight.w400),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                side: BorderSide(
                                    color: frequency == f
                                        ? _DS.brand.withOpacity(0.3)
                                        : _DS.border),
                              ))
                          .toList()),
                  const SizedBox(height: 18),
                ],
                Text('Điểm thưởng', style: _DS.label),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 20, 25, 30]
                        .map((p) => ChoiceChip(
                              label: Text('$p đ'),
                              selected: points == p,
                              selectedColor: _DS.warning.withOpacity(0.2),
                              onSelected: (_) => setModal(() => points = p),
                              labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: points == p
                                      ? FontWeight.w600
                                      : FontWeight.w400),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(
                                  color: points == p
                                      ? _DS.warning.withOpacity(0.3)
                                      : _DS.border),
                            ))
                        .toList()),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _DS.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
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
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Đã thêm việc mới')));
                        }
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    child: Text(
                        choreType == 'recurring'
                            ? 'Tạo việc xoay vòng'
                            : 'Tạo việc tự nhận',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip(String type, String label, IconData icon, String current,
      ValueChanged<String> onChange) {
    final selected = current == type;
    final color = type == 'recurring' ? _DS.brand : _DS.warning;
    return GestureDetector(
      onTap: () => onChange(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : _DS.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color.withOpacity(0.4) : _DS.border, width: 1),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? color : _DS.subtle, size: 22),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? color : _DS.subtle)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXPENSES TAB — Redesigned
// ─────────────────────────────────────────────
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
      for (var e in data) total += (e['amount'] ?? 0).toDouble();
      setState(() {
        expenses = data;
        totalExpense = total;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatMoney(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      body: Column(
        children: [
          _GreenHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chi tiêu',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          SizedBox(height: 2),
                          Text('Theo dõi & chia sẻ chi phí',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _summaryTile(
                            '${_formatMoney(totalExpense)} đ',
                            'Tổng chi tiêu',
                            Icons.account_balance_wallet_rounded)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _summaryTile('${expenses.length}', 'Giao dịch',
                            Icons.receipt_long_rounded)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(3),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: _DS.brand,
                    unselectedLabelColor: Colors.white.withOpacity(0.85),
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400),
                    dividerColor: Colors.transparent,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    tabs: const [
                      Tab(text: 'Ai nợ ai', height: 34),
                      Tab(text: 'Lịch sử', height: 34)
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: _DS.brand, strokeWidth: 2.5))
                : TabBarView(
                    controller: _tabController,
                    children: [_buildBalanceTab(), _buildHistoryTab()]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-expense');
          if (result == true) _loadData();
        },
        backgroundColor: _DS.brand,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text('Thêm chi tiêu',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _summaryTile(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.75), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3)),
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/balance-sheet'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _DS.card,
                  borderRadius: BorderRadius.circular(_DS.r16),
                  boxShadow: _DS.cardShadow),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: _DS.brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_rounded,
                        color: _DS.brand, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bảng Cân Đối Nợ', style: _DS.heading3),
                        const SizedBox(height: 2),
                        Text('Xem ai nợ ai và thanh toán',
                            style: _DS.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: _DS.subtle.withOpacity(0.5), size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _DS.info.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _DS.info.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _DS.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Khi bạn thêm chi tiêu và chia tiền, hệ thống tự động tính ai nợ ai.',
                        style: TextStyle(color: _DS.info, fontSize: 12.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: _DS.danger.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.receipt_long_outlined,
                  size: 28, color: _DS.danger.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            Text('Chưa có giao dịch', style: _DS.heading3),
            const SizedBox(height: 4),
            Text('Thêm chi tiêu đầu tiên!', style: _DS.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final title = expense['description'] ?? expense['title'] ?? 'Chi tiêu';
        final amount = (expense['amount'] ?? 0).toDouble();
        final paidBy = expense['paidByName'] ?? 'Unknown';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: _DS.card,
              borderRadius: BorderRadius.circular(_DS.r14),
              boxShadow: _DS.cardShadow),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: _DS.danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.receipt_rounded,
                    color: _DS.danger, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _DS.heading3),
                      const SizedBox(height: 2),
                      Text('$paidBy thanh toán', style: _DS.caption),
                    ]),
              ),
              Text('-${_formatMoney(amount)}đ',
                  style: const TextStyle(
                      color: _DS.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: -0.3)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// BULLETIN TAB — Redesigned
// ─────────────────────────────────────────────
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Đã sao chép!'),
      backgroundColor: _DS.brand,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.surface,
      body: Column(
        children: [
          _GreenHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bảng tin',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          SizedBox(height: 2),
                          Text('Thông tin & danh sách mua sắm',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      GestureDetector(
                        onTap: _showEditRoomInfoDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Row(children: [
                            Icon(Icons.edit_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Sửa',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ]),
                        ),
                      ),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 19),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FeedScreen()),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _DS.border),
                      boxShadow: _DS.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _DS.brand.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.newspaper_rounded,
                              color: _DS.brand, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Bảng tin tức',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0A9467))),
                              SizedBox(height: 3),
                              Text('Xem tin tức & sự kiện mới nhất',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: _DS.brand.withOpacity(0.85)),
                      ],
                    ),
                  ),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _buildWifiCard()),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildInfoCard(
                              icon: Icons.phone_rounded,
                              title: 'SĐT Chủ nhà',
                              info: landlordPhone.isEmpty
                                  ? '---'
                                  : landlordPhone)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: _DS.brand, strokeWidth: 2.5))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _DS.brand,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      children: [
                        _listHeader('Ghi chú', Icons.push_pin_rounded,
                            notes.length, _DS.brand, onAdd: () async {
                          final r =
                              await Navigator.pushNamed(context, '/add-note');
                          if (r == true) _loadData();
                        }),
                        const SizedBox(height: 10),
                        if (notes.isEmpty)
                          _emptyInline(
                              Icons.note_outlined, 'Chưa có ghi chú nào')
                        else
                          ...notes.map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildNoteCard(n))),
                        const SizedBox(height: 24),
                        _listHeader(
                          'Mua sắm',
                          Icons.shopping_bag_rounded,
                          shoppingItems
                              .where((i) => i['isPurchased'] != true)
                              .length,
                          _DS.warning,
                          onAdd: () async {
                            final r = await Navigator.pushNamed(
                                context, '/add-shopping-item');
                            if (r == true) _loadData();
                          },
                        ),
                        const SizedBox(height: 10),
                        if (shoppingItems.isEmpty)
                          _emptyInline(Icons.shopping_cart_outlined,
                              'Chưa có món nào cần mua')
                        else
                          ...shoppingItems.map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildShoppingItem(i))),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _listHeader(String title, IconData icon, int count, Color color,
      {required VoidCallback onAdd}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _DS.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Text('$count',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 11)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 17),
          ),
        ),
      ],
    );
  }

  Widget _emptyInline(IconData icon, String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          color: _DS.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _DS.cardShadow),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: _DS.subtle.withOpacity(0.4)),
          const SizedBox(width: 10),
          Text(msg, style: _DS.bodySmall),
        ],
      ),
    );
  }

  Widget _buildWifiCard() {
    final name = wifiName.isEmpty ? '---' : wifiName;
    final pass = wifiPassword.isEmpty ? '---' : wifiPassword;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.wifi_rounded, size: 14, color: _DS.brand),
            const SizedBox(width: 5),
            const Expanded(
                child: Text('WiFi',
                    style: TextStyle(fontSize: 10, color: _DS.textSecondary))),
            GestureDetector(
                onTap: () => _copyToClipboard(pass),
                child: Icon(Icons.copy_rounded, size: 13, color: _DS.brand)),
          ]),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _DS.textPrimary)),
          const SizedBox(height: 2),
          Text('MK: $pass', style: _DS.caption),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon, required String title, required String info}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: _DS.brand),
            const SizedBox(width: 5),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 10, color: _DS.textSecondary))),
            GestureDetector(
                onTap: () => _copyToClipboard(info),
                child: Icon(Icons.copy_rounded, size: 13, color: _DS.brand)),
          ]),
          const SizedBox(height: 6),
          Text(info,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _DS.textPrimary)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _DS.card,
        borderRadius: BorderRadius.circular(_DS.r14),
        border: isPinned
            ? Border.all(color: _DS.warning.withOpacity(0.3), width: 1)
            : null,
        boxShadow: _DS.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPinned) ...[
                _Pill('Ghim', color: _DS.warning, icon: Icons.push_pin_rounded),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: _DS.heading3)),
              GestureDetector(
                onTap: () => _confirmDeleteNote(note),
                child: Icon(Icons.delete_outline,
                    size: 18, color: _DS.danger.withOpacity(0.8)),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(content, style: _DS.body),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.person_outline_rounded,
                size: 12, color: _DS.subtle.withOpacity(0.5)),
            const SizedBox(width: 3),
            Text(authorName,
                style:
                    _DS.caption.copyWith(color: _DS.subtle.withOpacity(0.6))),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteNote(Map<String, dynamic> note) async {
    final noteId = note['id'] as String?;
    if (noteId == null || noteId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Không xác định được mã ghi chú'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _DS.elevatedShadow,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xóa ghi chú',
                  style: _DS.heading2.copyWith(color: _DS.textPrimary)),
              const SizedBox(height: 8),
              Text('Bạn có chắc muốn xóa ghi chú này?', style: _DS.body),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _DS.border),
                        foregroundColor: _DS.subtle,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await _deleteNote(noteId);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await FirestoreService.deleteNote(noteId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã xóa ghi chú'),
        backgroundColor: Colors.green,
      ));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi khi xóa: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Widget _buildShoppingItem(Map<String, dynamic> item) {
    final name = item['name'] ?? 'Món đồ';
    final isPurchased = item['isPurchased'] == true;
    final isExpenseLinked = item['expenseLinked'] == true;
    final itemId = item['id'] as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPurchased ? _DS.success.withOpacity(0.03) : _DS.card,
        borderRadius: BorderRadius.circular(12),
        border: isPurchased
            ? Border.all(color: _DS.success.withOpacity(0.15))
            : null,
        boxShadow: isPurchased ? null : _DS.cardShadow,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isPurchased ? _DS.success : Colors.transparent,
                border: Border.all(
                    color: isPurchased ? _DS.success : _DS.border, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: isPurchased
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: isPurchased ? TextDecoration.lineThrough : null,
                color: isPurchased ? _DS.subtle : _DS.onCard,
              ),
            ),
          ),
          if (isPurchased) ...[
            if (!isExpenseLinked)
              GestureDetector(
                onTap: () => _convertShoppingItemToExpense(item),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _DS.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(children: [
                    Icon(Icons.receipt_long_rounded,
                        color: _DS.warning, size: 13),
                    const SizedBox(width: 3),
                    Text('Chi tiêu',
                        style: TextStyle(
                            color: _DS.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              )
            else
              Icon(Icons.check_circle_rounded, color: _DS.success, size: 18),
          ],
        ],
      ),
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
        builder: (context, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Chuyển sang Chi tiêu',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Món: $name', style: _DS.bodySmall),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  suffixText: 'đ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12)),
                items: const [
                  DropdownMenuItem(value: 'Mua sắm', child: Text('Mua sắm')),
                  DropdownMenuItem(value: 'Ăn uống', child: Text('Ăn uống')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (v) => setDialog(() => category = v ?? 'Mua sắm'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Hủy', style: TextStyle(color: _DS.subtle))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _DS.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Tạo chi tiêu',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số tiền không hợp lệ')));
      return;
    }
    if (currentHouseId == null ||
        currentHouseId!.isEmpty ||
        currentUserId == null ||
        currentUserId!.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thiếu thông tin người dùng/phòng')));
      return;
    }

    try {
      final userName = await AuthService.getCurrentUserName() ?? 'Unknown';
      final members = await FirestoreService.getHouseMembers(currentHouseId!);
      if (members.isEmpty) throw Exception('Phòng chưa có thành viên');
      final splitAmount = amount / members.length;
      final splits = members
          .map((m) => {
                'userId': m['id'] as String,
                'userName': (m['name'] ?? 'Unknown').toString(),
                'amount': splitAmount
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
          splitWith: splits);
      if (itemId != null)
        await FirestoreService.updateShoppingItem(
            itemId, {'expenseLinked': true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chuyển sang Chi tiêu')));
        _loadData();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
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
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sửa thông tin phòng',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: _DS.surface,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: _DS.subtle),
                        ),
                      ),
                    ]),
                const SizedBox(height: 20),
                TextField(
                    controller: wifiNameCtrl,
                    decoration: _inputDeco('Tên WiFi', Icons.wifi_rounded)),
                const SizedBox(height: 12),
                TextField(
                    controller: wifiPassCtrl,
                    decoration:
                        _inputDeco('Mật khẩu WiFi', Icons.lock_rounded)),
                const SizedBox(height: 12),
                TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDeco('SĐT Chủ trọ', Icons.phone_rounded)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _DS.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0),
                    onPressed: () async {
                      try {
                        await FirestoreService.updateHouse(currentHouseId!, {
                          'wifiName': wifiNameCtrl.text,
                          'wifiPassword': wifiPassCtrl.text,
                          'landlordPhone': phoneCtrl.text
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Đã cập nhật thông tin')));
                        }
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                      }
                    },
                    child: const Text('Lưu thông tin',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),
              ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: _DS.bodySmall,
        prefixIcon: Icon(icon, size: 18, color: _DS.subtle),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _DS.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _DS.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _DS.brand, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ─────────────────────────────────────────────
// PROFILE TAB — Redesigned
// ─────────────────────────────────────────────
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
  String? _houseCode = '';
  String? _houseName = '';
  int _chorePoints = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final sessionUser = await AuthService.getFirebaseUser();
    final name = await AuthService.getCurrentUserName();
    final email = await AuthService.getCurrentUserEmail();
    final firebaseUserId = await AuthService.getFirebaseUserId();
    final firebaseHouseId = await AuthService.getFirebaseHouseId();

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
      _houseCode = houseCode ?? '';
      _houseName = houseName ?? '';
      _chorePoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GreenHeader(
          bottomPadding: 28,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 2.5),
                ),
                child: ClipOval(
                  child: UserAvatar(
                      name: _userName,
                      avatarUrl: _avatarUrl,
                      avatarBase64: _avatarBase64,
                      radius: 34,
                      backgroundColor: Colors.white,
                      textColor: _DS.brand),
                ),
              ),
              const SizedBox(height: 12),
              Text(_userName ?? 'Người dùng',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3)),
              const SizedBox(height: 3),
              Text(_userEmail ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: _DS.warning, size: 15),
                  const SizedBox(width: 5),
                  Text('$_chorePoints điểm',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _menuItem(
                  icon: Icons.account_circle_outlined,
                  title: 'Thông tin người dùng',
                  sub: 'Tên, email, ảnh đại diện',
                  onTap: () async {
                    final r =
                        await Navigator.pushNamed(context, '/profile-info');
                    if (r == true) _loadUserInfo();
                  }),
              _menuItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat phòng',
                  sub: 'Trò chuyện với thành viên trong phòng',
                  onTap: () => Navigator.pushNamed(context, '/chat')),
              _menuItem(
                  icon: Icons.home_outlined,
                  title: 'Mã phòng của tôi',
                  sub: _houseCode?.isNotEmpty == true
                      ? _houseCode!
                      : 'Chưa có phòng',
                  onTap: _showHouseCodeDialog),
              _menuItem(
                  icon: Icons.add_home_rounded,
                  title: 'Vào phòng khác',
                  sub: 'Nhập mã để join phòng',
                  onTap: _showJoinHouseDialog),
              _menuItem(
                  icon: Icons.leaderboard_rounded,
                  title: 'Xếp hạng',
                  sub: 'Bảng xếp hạng phòng',
                  onTap: () => Navigator.pushNamed(context, '/leaderboard')),
              _menuItem(
                  icon: Icons.settings_rounded,
                  title: 'Cài đặt',
                  sub: 'Cài đặt ứng dụng',
                  onTap: () => Navigator.pushNamed(context, '/settings')),
              _menuItem(
                  icon: Icons.notifications_rounded,
                  title: 'Thông báo',
                  sub: 'Quản lý thông báo',
                  onTap: () => Navigator.pushNamed(context, '/notifications')),
              _menuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp',
                  sub: 'Câu hỏi thường gặp',
                  onTap: _showHelpDialog),
              const SizedBox(height: 8),
              _menuItem(
                  icon: Icons.logout_rounded,
                  title: 'Đăng xuất',
                  sub: '',
                  onTap: _handleLogout,
                  isDanger: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(
      {required IconData icon,
      required String title,
      required String sub,
      required VoidCallback onTap,
      bool isDanger = false}) {
    final color = isDanger ? _DS.danger : _DS.onCard;
    final iconBg = isDanger ? _DS.danger.withOpacity(0.06) : _DS.surface;
    final iconColor = isDanger ? _DS.danger : _DS.subtle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _DS.card,
            borderRadius: BorderRadius.circular(_DS.r14),
            border: isDanger
                ? Border.all(color: _DS.danger.withOpacity(0.15))
                : null,
            boxShadow: isDanger ? null : _DS.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(sub, style: _DS.caption),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _DS.border, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Trợ giúp nhanh',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpRow('• Việc nhà: vào tab Công việc để nhận/hoàn thành.'),
              _helpRow('• Chi tiêu: thêm khoản mới ở tab Chi tiêu.'),
              _helpRow('• Bảng tin: lưu WiFi, SĐT và danh sách mua sắm.'),
              _helpRow('• Thông báo: xem nhắc việc và chi tiêu mới.'),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: TextStyle(color: _DS.brand)))
        ],
      ),
    );
  }

  Widget _helpRow(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: _DS.body),
      );

  void _showHouseCodeDialog() {
    if (_houseCode?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bạn chưa tham gia phòng nào'),
          backgroundColor: Colors.orange));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Mã phòng của tôi',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Phòng: $_houseName', style: _DS.bodySmall),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
                color: _DS.brand.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _DS.brand.withOpacity(0.3), width: 1)),
            child: SelectableText(_houseCode!,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _DS.brand,
                    letterSpacing: 4),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Text('Chia sẻ mã này để thành viên khác join phòng',
              textAlign: TextAlign.center, style: _DS.caption),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng', style: TextStyle(color: _DS.brand)))
        ],
      ),
    );
  }

  void _showJoinHouseDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0FB882), Color(0xFF0A9467)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Vào phòng khác',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nhập mã phòng để join:', style: _DS.bodySmall),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF7FBFA),
                        hintText: 'VD: ABC12345',
                        hintStyle:
                            TextStyle(color: _DS.subtle.withOpacity(0.45)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: _DS.border, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: _DS.brand.withOpacity(0.9), width: 1.7),
                        ),
                      ),
                      onChanged: (v) {
                        final upper = v.toUpperCase();
                        if (codeController.text != upper) {
                          codeController.value = TextEditingValue(
                            text: upper,
                            selection:
                                TextSelection.collapsed(offset: upper.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _DS.subtle,
                              side: BorderSide(color: _DS.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _DS.brand,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (codeController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Vui lòng nhập mã phòng')));
                                return;
                              }
                              try {
                                final userId =
                                    await AuthService.getFirebaseUserId();
                                if (userId == null)
                                  throw Exception('User not found');
                                final result =
                                    await FirestoreService.joinHouseByCode(
                                        joinCode: codeController.text
                                            .trim()
                                            .toUpperCase(),
                                        userId: userId);
                                if (result['success'] == true) {
                                  await AuthService.updateFirebaseHouseId(
                                      result['houseId']);
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Vào phòng thành công'),
                                            backgroundColor: Colors.green));
                                    _loadUserInfo();
                                  }
                                } else {
                                  throw Exception(result['message'] ??
                                      'Vào phòng thất bại');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(e
                                              .toString()
                                              .replaceAll("Exception: ", "")),
                                          backgroundColor: Colors.red));
                                }
                              }
                            },
                            child: const Text('Vào phòng',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
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
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _currentHouseId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final houseId = await AuthService.getFirebaseHouseId();
      if (houseId == null || houseId.isEmpty) {
        Navigator.pop(context);
        return;
      }

      setState(() {
        _currentHouseId = houseId;
      });

      final members = await FirestoreService.getHouseMembers(houseId);
      
      // Sort by chorePoints descending
      members.sort((a, b) => ((b['chorePoints'] as num?) ?? 0).compareTo((a['chorePoints'] as num?) ?? 0));

      setState(() {
        _users = members;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
        ),
        title: const Text(
          'Bảng xếp hạng',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thành viên',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.warning, Color(0xFFFFB74D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.textWhite,
                            size: 48,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.textWhite,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thành viên tích cực nhất',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textWhite.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Top 3
                    if (_users.isNotEmpty) ...[
                      _buildTopThreeFromMap(_users),
                      const SizedBox(height: 24),
                    ],
                    // Rankings
                    const Text(
                      'Xếp hạng',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 12),
                    ..._users.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return _buildRankingCardFromMap(user, index + 1);
                    }),
                  ],
                ),
    );
  }

  Widget _buildTopThreeFromMap(List<Map<String, dynamic>> users) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (users.length > 1) Expanded(child: _buildPodiumFromMap(users[1], 2, 140)),
        if (users.isNotEmpty) Expanded(child: _buildPodiumFromMap(users[0], 1, 180)),
        if (users.length > 2) Expanded(child: _buildPodiumFromMap(users[2], 3, 120)),
      ],
    );
  }

  Widget _buildPodiumFromMap(Map<String, dynamic> user, int rank, double height) {
    final name = user['name'] ?? 'Unknown';
    final chorePoints = user['chorePoints'] ?? 0;
    
    Color color;
    IconData medal;
    
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700); // Gold
        medal = Icons.workspace_premium_rounded;
        break;
      case 2:
        color = const Color(0xFFC0C0C0); // Silver
        medal = Icons.workspace_premium_rounded;
        break;
      case 3:
        color = const Color(0xFFCD7F32); // Bronze
        medal = Icons.workspace_premium_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        medal = Icons.emoji_events_rounded;
    }

    return Column(
      children: [
        // Avatar & Medal
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 35,
                backgroundColor: color.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: rank == 1 ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                medal,
                color: AppColors.textWhite,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          name,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '$chorePoints điểm',
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCardFromMap(Map<String, dynamic> user, int rank) {
    final name = user['name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final chorePoints = user['chorePoints'] ?? 0;
    
    Color? medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700);
      medalIcon = Icons.workspace_premium_rounded;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0);
      medalIcon = Icons.workspace_premium_rounded;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32);
      medalIcon = Icons.workspace_premium_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: medalColor!.withOpacity(0.3), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? medalColor!.withOpacity(0.2)
                  : AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      medalIcon,
                      color: medalColor,
                      size: 24,
                    )
                  : Text(
                      '#$rank',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                Text(
                  email,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$chorePoints',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'điểm',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree(List<User> users) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (users.length > 1) Expanded(child: _buildPodium(users[1], 2, 140)),
        if (users.isNotEmpty) Expanded(child: _buildPodium(users[0], 1, 180)),
        if (users.length > 2) Expanded(child: _buildPodium(users[2], 3, 120)),
      ],
    );
  }

  Widget _buildPodium(User user, int rank, double height) {
    Color color;
    IconData medal;
    
    switch (rank) {
      case 1:
        color = const Color(0xFFFFD700); // Gold
        medal = Icons.workspace_premium_rounded;
        break;
      case 2:
        color = const Color(0xFFC0C0C0); // Silver
        medal = Icons.workspace_premium_rounded;
        break;
      case 3:
        color = const Color(0xFFCD7F32); // Bronze
        medal = Icons.workspace_premium_rounded;
        break;
      default:
        color = AppColors.textSecondary;
        medal = Icons.emoji_events_rounded;
    }

    return Column(
      children: [
        // Avatar & Medal
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: CircleAvatar(
                radius: rank == 1 ? 40 : 35,
                backgroundColor: color.withOpacity(0.2),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: rank == 1 ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                medal,
                color: AppColors.textWhite,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Name
        Text(
          user.name,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '${user.chorePoints} điểm',
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard(User user, int rank) {
    Color? medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700);
      medalIcon = Icons.workspace_premium_rounded;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0);
      medalIcon = Icons.workspace_premium_rounded;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32);
      medalIcon = Icons.workspace_premium_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: medalColor!.withOpacity(0.3), width: 2)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? medalColor!.withOpacity(0.2)
                  : AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      medalIcon,
                      color: medalColor,
                      size: 24,
                    )
                  : Text(
                      '#$rank',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                Text(
                  user.email,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${user.chorePoints}',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'điểm',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

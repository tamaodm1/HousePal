import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ChoresDetailScreen extends StatefulWidget {
  const ChoresDetailScreen({super.key});

  @override
  State<ChoresDetailScreen> createState() => _ChoresDetailScreenState();
}

class _ChoresDetailScreenState extends State<ChoresDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data từ Firebase - 2 loại việc
  List<Map<String, dynamic>> recurringChores = []; // Việc xoay vòng
  List<Map<String, dynamic>> oneTimeChores = [];   // Việc tự nhận
  List<Map<String, dynamic>> leaderboard = [];
  
  String? currentUserId;
  String? currentUserName;
  String? currentHouseId;
  bool isAdmin = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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

      // Lấy thông tin user
      final userData = await FirestoreService.getUserById(currentUserId!);
      currentUserName = userData?['name'] ?? 'User';
      
      // Kiểm tra admin (owner của house)
      final houseData = await FirestoreService.getHouseById(currentHouseId!);
      final ownerId = houseData?['ownerId'];
      
      // Nếu house cũ chưa có owner, set user hiện tại làm owner
      if (ownerId == null || ownerId.toString().isEmpty) {
        await FirestoreService.setHouseOwner(currentHouseId!, currentUserId!);
        isAdmin = true;
      } else {
        isAdmin = ownerId == currentUserId;
      }
      
      // Load 2 loại chores
      final recurring = await FirestoreService.getRecurringChores(currentHouseId!);
      final oneTime = await FirestoreService.getOneTimeChores(currentHouseId!);
      
      // Load leaderboard
      final members = await FirestoreService.getHouseMembers(currentHouseId!);
      members.sort((a, b) => ((b['chorePoints'] as num?) ?? 0).compareTo((a['chorePoints'] as num?) ?? 0));

      setState(() {
        recurringChores = recurring;
        oneTimeChores = oneTime;
        leaderboard = members;
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.black),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Việc nhà',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🏠 Quản lý & xoay vòng công việc',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: '🔄 Xoay vòng'),
                        Tab(text: '📋 Tự nhận'),
                        Tab(text: '🏆 Xếp hạng'),
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
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Lỗi: $errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadData, child: const Text('Thử lại')),
                          ],
                        ),
                      )
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
      return _buildEmptyState('Chưa có việc xoay vòng', Icons.sync_disabled, 'Việc xoay vòng tự động luân phiên giữa các thành viên');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ...recurringChores.map((chore) => _buildRecurringCard(chore)),
      ],
    );
  }

  // ============ TAB TỰ NHẬN ============
  Widget _buildOneTimeTab() {
    final availableChores = oneTimeChores.where((c) => c['status'] == 'available').toList();
    final claimedChores = oneTimeChores.where((c) => c['status'] == 'claimed').toList();
    
    if (oneTimeChores.isEmpty) {
      return _buildEmptyState('Chưa có việc cần nhận', Icons.inbox, 'Việc tự nhận ai muốn làm thì nhận');
    }
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (availableChores.isNotEmpty) ...[
          _buildSectionHeader('🆕 Đang chờ nhận', Colors.green, availableChores.length),
          ...availableChores.map((chore) => _buildOneTimeCard(chore)),
        ],
        if (claimedChores.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('👤 Đã có người nhận', Colors.blue, claimedChores.length),
          ...claimedChores.map((chore) => _buildOneTimeCard(chore)),
        ],
      ],
    );
  }

  // ============ CARD VIỆC XOAY VÒNG ============
  Widget _buildRecurringCard(Map<String, dynamic> chore) {
    final choreId = chore['id'] as String;
    final title = chore['title'] ?? 'Việc';
    final description = chore['description'] as String?;
    final frequency = chore['frequency'] ?? 'daily';
    final points = chore['points'] ?? 10;
    final currentAssigneeId = chore['currentAssigneeId'] ?? '';
    final currentAssigneeName = chore['currentAssigneeName'] ?? 'Chưa giao';
    final isMyTurn = currentAssigneeId == currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTurn ? AppColors.primary : Colors.grey.shade300,
          width: isMyTurn ? 2 : 1,
        ),
        boxShadow: isMyTurn ? [
          BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
        ] : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sync, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (description != null && description.isNotEmpty)
                            Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    if (isMyTurn)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('⭐ Lượt bạn!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info row
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Lượt của: $currentAssigneeName',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    _buildTag(_getFrequencyText(frequency), _getFrequencyColor(frequency)),
                    const SizedBox(width: 8),
                    _buildTag('$points điểm', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          // Button hoàn thành
          if (isMyTurn)
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text('Hoàn thành & Chuyển lượt', style: TextStyle(color: Colors.white)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimedByMe ? Colors.orange : (isAvailable ? Colors.green : Colors.blue),
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
                        color: (isAvailable ? Colors.green : Colors.blue).withOpacity(0.1),
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
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          if (description != null && description.isNotEmpty)
                            Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
                        isClaimedByMe ? '📌 Bạn đã nhận việc này' : 'Đã nhận bởi: $claimedByUserName',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Buttons
          if (isAvailable)
            _buildCardButton(
              onPressed: () => _claimChore(chore),
              label: '🙋 Nhận việc này',
              color: Colors.green,
            ),
          if (isClaimedByMe)
            _buildCardButton(
              onPressed: () => _completeOneTimeChore(chore),
              label: '✅ Hoàn thành',
              color: AppColors.primary,
            ),
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
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCardButton({required VoidCallback onPressed, required String label, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
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
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade500), textAlign: TextAlign.center),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddChoreDialog,
                icon: const Icon(Icons.add),
                label: const Text('Thêm việc mới'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency) {
      case 'daily': return 'Hàng ngày';
      case 'weekly': return 'Hàng tuần';
      case 'monthly': return 'Hàng tháng';
      default: return frequency;
    }
  }

  Color _getFrequencyColor(String frequency) {
    switch (frequency) {
      case 'daily': return Colors.red;
      case 'weekly': return Colors.blue;
      case 'monthly': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // ============ ACTIONS ============
  
  Future<void> _claimChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    try {
      await FirestoreService.claimChore(choreId, currentUserId!, currentUserName!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã nhận việc thành công!')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Future<void> _completeRecurringChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 Hoàn thành! +$points điểm. Đã chuyển lượt.')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Future<void> _completeOneTimeChore(Map<String, dynamic> chore) async {
    final choreId = chore['id'] as String;
    final points = chore['points'] ?? 10;
    try {
      await FirestoreService.completeChore(choreId, currentUserId!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 Hoàn thành! +$points điểm')));
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  // ============ FORM THÊM VIỆC ============
  void _showAddChoreDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String choreType = 'recurring';
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
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
                          const Text('➕ Thêm việc mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Chọn loại
                      const Text('Loại việc', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTypeSelector('🔄 Xoay vòng', 'Tự động luân phiên', choreType == 'recurring', () => setModalState(() => choreType = 'recurring'))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeSelector('📋 Tự nhận', 'Ai muốn thì nhận', choreType == 'one-time', () => setModalState(() => choreType = 'one-time'))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Tên việc
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tên việc *',
                          hintText: choreType == 'recurring' ? 'VD: Rửa bát, Đổ rác' : 'VD: Mua đồ ăn',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mô tả
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mô tả (tùy chọn)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tần suất (chỉ recurring)
                      if (choreType == 'recurring') ...[
                        const Text('Tần suất', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['daily', 'weekly', 'monthly'].map((f) {
                            final isSelected = selectedFrequency == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_getFrequencyText(f)),
                                selected: isSelected,
                                onSelected: (_) => setModalState(() => selectedFrequency = f),
                                selectedColor: _getFrequencyColor(f).withOpacity(0.3),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Điểm
                      const Text('Điểm thưởng', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [5, 10, 15, 20].map((p) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$p điểm'),
                              selected: points == p,
                              onSelected: (_) => setModalState(() => points = p),
                              selectedColor: Colors.orange.withOpacity(0.3),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Button tạo
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên việc')));
                              return;
                            }
                            try {
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
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Đã tạo ${choreType == 'recurring' ? 'việc xoay vòng' : 'việc tự nhận'}!')));
                                _loadData();
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(16)),
                          child: Text(choreType == 'recurring' ? '🔄 Tạo việc xoay vòng' : '📋 Tạo việc tự nhận', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildTypeSelector(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ============ LEADERBOARD TAB ============
  Widget _buildLeaderboardTab() {
    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có thành viên',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Thành viên tích cực nhất',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Top 3 Podium
        if (leaderboard.length >= 3) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place
              Expanded(
                child: _buildPodiumCard(
                  leaderboard[1],
                  height: 140,
                  medal: '🥈',
                ),
              ),
              const SizedBox(width: 8),
              // 1st Place
              Expanded(
                child: _buildPodiumCard(
                  leaderboard[0],
                  height: 180,
                  medal: '🥇',
                ),
              ),
              const SizedBox(width: 8),
              // 3rd Place
              Expanded(
                child: _buildPodiumCard(
                  leaderboard[2],
                  height: 120,
                  medal: '🥉',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        
        // Ranking List
        Text(
          'Xếp hạng',
          style: AppTextStyles.h4.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...leaderboard.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;
          final rank = index + 1;
          final isTopThree = rank <= 3;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isTopThree ? AppColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTopThree ? AppColors.primary : const Color(0xFFE0E0E0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isTopThree ? AppColors.primary : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      rank.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTopThree ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFA500)),
                          const SizedBox(width: 4),
                          Text(
                            '${user['chorePoints'] ?? 0} điểm',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isTopThree ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${user['chorePoints'] ?? 0} điểm',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> user, {required double height, required String medal}) {
    final name = user['name'] ?? 'Unknown';
    final chorePoints = user['chorePoints'] ?? 0;
    
    return Column(
      children: [
        Text(
          medal,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '$chorePoints điểm',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

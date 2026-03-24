import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _houseNameController = TextEditingController();
  final _choreReminderController = TextEditingController(text: '08:00');
  final _wifiNameController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  final _landlordPhoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _choreReminderEnabled = true;
  bool _expenseNotificationEnabled = true;
  bool _isAdmin = false;
  String? _houseId;
  String? _userId;
  String _joinCode = '';
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _userId = await AuthService.getFirebaseUserId();
      _houseId = await AuthService.getFirebaseHouseId();

      if (_houseId == null || _houseId!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final house = await FirestoreService.getHouseById(_houseId!);
      final members = await FirestoreService.getHouseMembers(_houseId!);
      final pendingRequests = _isAdmin ? await FirestoreService.getPendingJoinRequests(_houseId!) : <Map<String, dynamic>>[];

      _isAdmin = (house?['ownerId'] ?? '') == _userId;
      _houseNameController.text = (house?['name'] ?? '').toString();
      _joinCode = (house?['joinCode'] ?? '').toString();
      _wifiNameController.text = (house?['wifiName'] ?? '').toString();
      _wifiPasswordController.text = (house?['wifiPassword'] ?? '').toString();
      _landlordPhoneController.text =
          (house?['landlordPhone'] ?? '').toString();
      _choreReminderEnabled = house?['choreReminderEnabled'] ?? true;
      _expenseNotificationEnabled =
          house?['expenseNotificationEnabled'] ?? true;
      _choreReminderController.text =
          (house?['choreReminderTime'] ?? '08:00').toString();

      setState(() {
        _members = members;
        _pendingRequests = pendingRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_houseId == null || _houseId!.isEmpty || !_isAdmin) return;

    setState(() => _isSaving = true);
    try {
      await FirestoreService.updateHouse(_houseId!, {
        'name': _houseNameController.text.trim(),
        'wifiName': _wifiNameController.text.trim(),
        'wifiPassword': _wifiPasswordController.text.trim(),
        'landlordPhone': _landlordPhoneController.text.trim(),
        'choreReminderEnabled': _choreReminderEnabled,
        'expenseNotificationEnabled': _expenseNotificationEnabled,
        'choreReminderTime': _choreReminderController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cài đặt đã được lưu')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final memberId = (member['id'] ?? '').toString();
    if (!_isAdmin || memberId.isEmpty || _houseId == null) return;

    final isOwner = memberId == _userId;
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Admin không thể tự xóa chính mình. Hãy dùng "Rời khỏi Nhà".')),
      );
      return;
    }

    await FirestoreService.leaveHouse(userId: memberId, houseId: _houseId!);
    await _loadData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa thành viên khỏi phòng')),
    );
  }

  Future<void> _leaveHouse() async {
    if (_houseId == null ||
        _houseId!.isEmpty ||
        _userId == null ||
        _userId!.isEmpty) return;

    if (_isAdmin && _members.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admin chưa thể rời phòng khi còn thành viên khác.')),
      );
      return;
    }

    await FirestoreService.leaveHouse(userId: _userId!, houseId: _houseId!);
    await AuthService.updateFirebaseHouseId('');
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bạn đã rời khỏi phòng')),
    );
  }

  Future<void> _approveJoinRequest(String requestId, String userId) async {
    if (_houseId == null || _userId == null) return;
    
    try {
      await FirestoreService.approveJoinRequest(
        houseId: _houseId!,
        requestId: requestId,
        userId: userId,
        adminId: _userId!,
      );
      
      _loadData(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt yêu cầu tham gia')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(String requestId, String userId) async {
    if (_houseId == null || _userId == null) return;
    
    try {
      await FirestoreService.rejectJoinRequest(
        houseId: _houseId!,
        requestId: requestId,
        userId: userId,
        adminId: _userId!,
      );
      
      _loadData(); // Reload data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối yêu cầu tham gia')),
        );
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
  void dispose() {
    _houseNameController.dispose();
    _choreReminderController.dispose();
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    _landlordPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Nhà'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // House Info Section
                  Text(
                    'Thông tin Nhà',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _houseNameController,
                    readOnly: !_isAdmin,
                    decoration: InputDecoration(
                      labelText: 'Tên nhà/phòng',
                      hintText: 'Ví dụ: Nhà số 42, Căn hộ 3B',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wifiNameController,
                    readOnly: !_isAdmin,
                    decoration: InputDecoration(
                      labelText: 'Tên WiFi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _wifiPasswordController,
                    readOnly: !_isAdmin,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu WiFi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _landlordPhoneController,
                    readOnly: !_isAdmin,
                    decoration: InputDecoration(
                      labelText: 'SĐT chủ nhà',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    readOnly: true,
                    initialValue: _joinCode,
                    decoration: InputDecoration(
                      labelText: 'Mã Nhà',
                      hintText: 'Chưa có',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pending Join Requests Section (for admins only)
                  if (_isAdmin && _pendingRequests.isNotEmpty) ...[
                    Text(
                      'Yêu cầu tham gia (${_pendingRequests.length})',
                      style: AppTextStyles.h4.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...(_pendingRequests.map((request) {
                      final userId = request['userId'] ?? '';
                      final userName = request['userName'] ?? 'Người dùng';
                      final requestId = request['id'] ?? '';
                      
                      return Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(request['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Duyệt'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _approveJoinRequest(requestId, userId),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Từ chối'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _rejectJoinRequest(requestId, userId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                    const SizedBox(height: 24),
                  ],

                  // Members Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thành viên (${_members.length})',
                        style: AppTextStyles.h4.copyWith(fontSize: 16),
                      ),
                      if (_isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Admin',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._members.map((m) {
                    final isOwner = (m['id'] ?? '').toString() == _userId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMemberItem(
                        (m['name'] ?? 'Unknown').toString(),
                        isOwner ? 'Admin' : 'Thành viên',
                        isOwner ? Colors.blue : Colors.grey,
                        avatarUrl: (m['avatarUrl'] ?? '').toString(),
                        avatarBase64: (m['avatarBase64'] ?? '').toString(),
                        onRemove: _isAdmin && !isOwner
                            ? () => _removeMember(m)
                            : null,
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Notifications Section
                  Text(
                    'Thông báo',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    value: _choreReminderEnabled,
                    onChanged: (value) =>
                        setState(() => _choreReminderEnabled = value),
                    title: const Text('Nhắc nhở công việc'),
                    subtitle: const Text('Nhận thông báo khi đến lượt bạn'),
                  ),

                  SwitchListTile(
                    value: _expenseNotificationEnabled,
                    onChanged: (value) =>
                        setState(() => _expenseNotificationEnabled = value),
                    title: const Text('Cập nhật chi tiêu'),
                    subtitle: const Text('Nhận thông báo khi có chi tiêu mới'),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _choreReminderController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Giờ nhắc nhở công việc',
                      hintText: '08:00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        _choreReminderController.text = time.format(context);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Game Section
                  Text(
                    'Game hóa & Điểm',
                    style: AppTextStyles.h4.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Điểm cho mỗi công việc',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildPointRule('Công việc dễ', '5 điểm'),
                        const SizedBox(height: 8),
                        _buildPointRule('Công việc thường', '10 điểm'),
                        const SizedBox(height: 8),
                        _buildPointRule('Công việc khó', '20 điểm'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAdmin && !_isSaving ? _saveSettings : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Lưu Cài đặt'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Danger Zone
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _leaveHouse,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text(
                        'Rời khỏi Nhà',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMemberItem(String name, String role, Color color,
      {String? avatarUrl,
      String? avatarBase64,
      VoidCallback? onRemove}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          UserAvatar(
            name: name,
            avatarUrl: avatarUrl,
            avatarBase64: avatarBase64,
            radius: 18,
            backgroundColor: color.withOpacity(0.2),
            textColor: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  role,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_alt_1, color: Colors.red),
              tooltip: 'Xóa khỏi phòng',
            ),
        ],
      ),
    );
  }

  Widget _buildPointRule(String activity, String points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(activity),
        Text(
          points,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}

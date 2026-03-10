import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _houseNameController = TextEditingController(text: 'Nhà số 42');
  final _choreReminderController = TextEditingController(text: '08:00');
  
  @override
  void dispose() {
    _houseNameController.dispose();
    _choreReminderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt Nhà'),
      ),
      body: SingleChildScrollView(
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
              decoration: InputDecoration(
                labelText: 'Tên nhà/phòng',
                hintText: 'Ví dụ: Nhà số 42, Căn hộ 3B',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Mã Nhà',
                hintText: 'HOUSE-2024-001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Members Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành viên (5)',
                  style: AppTextStyles.h4.copyWith(fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildMemberItem('An', 'Admin', Colors.blue),
            const SizedBox(height: 8),
            _buildMemberItem('Bình', 'Thành viên', Colors.grey),
            const SizedBox(height: 8),
            _buildMemberItem('Dũng', 'Thành viên', Colors.grey),
            const SizedBox(height: 8),
            _buildMemberItem('Hương', 'Thành viên', Colors.grey),
            const SizedBox(height: 8),
            _buildMemberItem('Thành', 'Thành viên', Colors.grey),
            
            const SizedBox(height: 24),
            
            // Notifications Section
            Text(
              'Thông báo',
              style: AppTextStyles.h4.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              value: true,
              onChanged: (value) {},
              title: const Text('Nhắc nhở công việc'),
              subtitle: const Text('Nhận thông báo khi đến lượt bạn'),
            ),
            
            SwitchListTile(
              value: true,
              onChanged: (value) {},
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cài đặt đã được lưu'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Lưu Cài đặt'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Danger Zone
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
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

  Widget _buildMemberItem(String name, String role, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(Icons.person, color: color),
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
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('Xem chi tiết'),
              ),
              const PopupMenuItem(
                child: Text('Xóa'),
              ),
            ],
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class ExpenseSplitScreen extends StatefulWidget {
  const ExpenseSplitScreen({super.key});

  @override
  State<ExpenseSplitScreen> createState() => _ExpenseSplitScreenState();
}

class _ExpenseSplitScreenState extends State<ExpenseSplitScreen> {
  String _splitType = 'equal'; // equal, custom, people
  final List<String> members = ['An', 'Bình', 'Dũng', 'Hương', 'Thành'];
  late Map<String, bool> selectedMembers;
  late Map<String, double> customPercentages;

  @override
  void initState() {
    super.initState();
    selectedMembers = {for (var m in members) m: true};
    customPercentages = {for (var m in members) m: 20.0};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn cách chia tiền'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Split Type Selection
            Text(
              'Cách chia tiền',
              style: AppTextStyles.h4.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // Chia đều
            _buildSplitTypeCard(
              type: 'equal',
              title: 'Chia đều',
              description: 'Chia đều cho tất cả thành viên',
              icon: Icons.balance_outlined,
            ),
            const SizedBox(height: 12),
            
            // Chia theo tỷ lệ
            _buildSplitTypeCard(
              type: 'custom',
              title: 'Chia theo tỷ lệ',
              description: 'Tự định % cho từng người',
              icon: Icons.bar_chart_rounded,
            ),
            const SizedBox(height: 12),
            
            // Chia theo người
            _buildSplitTypeCard(
              type: 'people',
              title: 'Chia theo người dùng',
              description: 'Chỉ những ai dùng thực tế',
              icon: Icons.people_outlined,
            ),
            
            const SizedBox(height: 24),
            
            // Split Details
            if (_splitType == 'equal') ...[
              _buildEqualSplitDetail(),
            ] else if (_splitType == 'custom') ...[
              _buildCustomSplitDetail(),
            ] else if (_splitType == 'people') ...[
              _buildPeopleSplitDetail(),
            ],
            
            const SizedBox(height: 24),
            
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Xác nhận cách chia'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitTypeCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _splitType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _splitType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualSplitDetail() {
    const totalAmount = 500000;
    final splitAmount = totalAmount / members.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết chia đều',
          style: AppTextStyles.h4.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng tiền: ${totalAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Số người: ${members.length}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                'Mỗi người trả: ${splitAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSplitDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Định % cho từng người',
          style: AppTextStyles.h4.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      member,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '${customPercentages[member]?.toInt()}%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPeopleSplitDetail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn người dùng',
          style: AppTextStyles.h4.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: CheckboxListTile(
                value: selectedMembers[member] ?? false,
                onChanged: (value) {
                  setState(() {
                    selectedMembers[member] = value ?? false;
                  });
                },
                title: Text(member),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

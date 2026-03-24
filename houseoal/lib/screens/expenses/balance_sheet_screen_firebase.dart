import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  List<Map<String, dynamic>> debts = [];
  String? currentUserId;
  String? currentUserName;
  String? houseId;
  bool isLoading = true;
  String? errorMessage;
  
  double totalOwes = 0; // Bạn nợ người khác
  double totalOwed = 0; // Người khác nợ bạn

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      currentUserId = await AuthService.getFirebaseUserId();
      currentUserName = await AuthService.getCurrentUserName();
      houseId = await AuthService.getFirebaseHouseId();
      
      if (houseId == null || houseId!.isEmpty) {
        setState(() {
          errorMessage = 'Bạn chưa tham gia phòng nào';
          isLoading = false;
        });
        return;
      }
      
      // Load debts từ Firebase
      final debtsList = await FirestoreService.getDebtsByHouse(houseId!);
      
      // Tính tổng nợ
      double owes = 0;
      double owed = 0;
      for (var debt in debtsList) {
        final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
        if (debt['debtorId'] == currentUserId) {
          owes += amount;
        }
        if (debt['creditorId'] == currentUserId) {
          owed += amount;
        }
      }

      setState(() {
        debts = debtsList;
        totalOwes = owes;
        totalOwed = owed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _settleDebt(String debtId) async {
    try {
      await FirestoreService.settleDebt(debtId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận thanh toán!'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Cân Đối Nợ'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Đã xảy ra lỗi',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),

            if (debts.isNotEmpty) ...[
              Text(
                'Chi tiết Nợ (${debts.length})',
                style: AppTextStyles.h4.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDebtList(),
            ] else ...[
              _buildEmptyState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final netBalance = totalOwed - totalOwes;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tóm tắt Nợ của bạn',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bạn nợ',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMoney(totalOwes)}đ',
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Người khác nợ bạn',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatMoney(totalOwed)}đ',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.black26),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Số dư ròng',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                '${netBalance >= 0 ? '+' : ''}${_formatMoney(netBalance)}đ',
                style: TextStyle(
                  color: netBalance >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFD32F2F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        final isDebtToYou = debt['creditorId'] == currentUserId;
        final isYouOwe = debt['debtorId'] == currentUserId;
        final amount = (debt['amount'] as num?)?.toDouble() ?? 0;

        Color cardColor;
        IconData iconData;
        String titleText;

        if (isDebtToYou) {
          cardColor = const Color(0xFF4CAF50);
          iconData = Icons.arrow_downward;
          titleText = '${debt['debtorName']} nợ bạn';
        } else if (isYouOwe) {
          cardColor = const Color(0xFFD32F2F);
          iconData = Icons.arrow_upward;
          titleText = 'Bạn nợ ${debt['creditorName']}';
        } else {
          cardColor = Colors.orange;
          iconData = Icons.swap_horiz;
          titleText = '${debt['debtorName']} nợ ${debt['creditorName']}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(iconData, color: cardColor)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(debt['description'] ?? 'Chi tiêu dùng chung', style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatMoney(amount)}đ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cardColor),
                  ),
                  const SizedBox(height: 4),
                  if (isDebtToYou) // Chỉ creditor mới thấy nút xác nhận
                    ElevatedButton(
                      onPressed: () => _showSettleDialog(debt),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: cardColor,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettleDialog(Map<String, dynamic> debt) {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số tiền: ${_formatMoney(amount)}đ', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${debt['debtorName']} đã trả cho bạn?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _settleDebt(debt['id']);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Không có nợ nào', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tất cả đã được thanh toán!', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm chi tiêu mới trong tab "Chi tiêu" để tạo các khoản nợ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

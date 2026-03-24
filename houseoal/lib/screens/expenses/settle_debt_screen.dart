import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SettleDebtScreen extends StatefulWidget {
  const SettleDebtScreen({super.key});

  @override
  State<SettleDebtScreen> createState() => _SettleDebtScreenState();
}

class _SettleDebtScreenState extends State<SettleDebtScreen> {
  bool _isLoading = true;
  String? _error;
  String? _houseId;
  String? _userId;
  List<Map<String, dynamic>> _debts = [];

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

      _houseId = await AuthService.getFirebaseHouseId();
      _userId = await AuthService.getFirebaseUserId();
      if (_houseId == null ||
          _houseId!.isEmpty ||
          _userId == null ||
          _userId!.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Bạn chưa tham gia phòng';
        });
        return;
      }

      final debts = await FirestoreService.getDebtsByHouse(_houseId!);
      final myDebts = debts
          .where((d) => d['debtorId'] == _userId || d['creditorId'] == _userId)
          .toList();

      setState(() {
        _debts = myDebts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _money(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _confirmSettle(Map<String, dynamic> debt) async {
    final amount = (debt['amount'] as num?)?.toDouble() ?? 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận thanh toán'),
        content: Text(
          'Bạn xác nhận đã nhận ${_money(amount)}đ từ ${debt['debtorName']}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );

    if (ok != true) return;
    await FirestoreService.settleDebt(debt['id'] as String);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã chốt thanh toán')),
    );
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán nợ'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _debts.isEmpty
                  ? const Center(child: Text('Không có khoản nợ nào cần chốt'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _debts.length,
                      itemBuilder: (context, index) {
                        final debt = _debts[index];
                        final isYouDebtor = debt['debtorId'] == _userId;
                        final amount =
                            (debt['amount'] as num?)?.toDouble() ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E5E5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isYouDebtor
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isYouDebtor ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isYouDebtor
                                          ? 'Bạn nợ ${debt['creditorName']}'
                                          : '${debt['debtorName']} nợ bạn',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Số tiền: ${_money(amount)}đ'),
                                  ],
                                ),
                              ),
                              if (!isYouDebtor) // Chỉ creditor mới thấy nút xác nhận
                                ElevatedButton(
                                  onPressed: () => _confirmSettle(debt),
                                  child: const Text('Xác nhận'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

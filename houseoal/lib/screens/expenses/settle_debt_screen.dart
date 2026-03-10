import 'package:flutter/material.dart';

class SettleDebtScreen extends StatefulWidget {
  const SettleDebtScreen({super.key});

  @override
  State<SettleDebtScreen> createState() => _SettleDebtScreenState();
}

class _SettleDebtScreenState extends State<SettleDebtScreen> {
  final _amountController = TextEditingController();
  String? _selectedFrom;
  String? _selectedTo;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán nợ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFrom,
              decoration: InputDecoration(
                hintText: 'Từ người',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['Thành viên 1', 'Thành viên 2', 'Thành viên 3']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrom = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedTo,
              decoration: InputDecoration(
                hintText: 'Cho người',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['Thành viên 1', 'Thành viên 2', 'Thành viên 3']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTo = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Số tiền thanh toán (VNĐ)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Xác nhận thanh toán'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

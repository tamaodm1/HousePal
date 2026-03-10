import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              'Thông báo ${index + 1}',
              style: AppTextStyles.bodyLarge,
            ),
            subtitle: const Text('Một vài giây trước'),
            trailing: index % 3 == 0
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : null,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isLoggedIn = await AuthService.isUserLoggedIn();
    if (!mounted) return;
    if (isLoggedIn) {
      // Kiểm tra xem user đã có houseId chưa
      final userData = await AuthService.getFirebaseUser();
      if (userData != null && userData['houseId'] != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/select-house');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // Welcome text
              Text(
                'Chào mừng đã đến với',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Logo
              Image.asset(
                'img/logo.png',
                width: 250,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'Giải pháp toàn diện để quản lý nhà trọ/chung cư',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Taglines
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Chuyên nghiệp - tự động hóa\n',
                    ),
                    TextSpan(
                      text: 'Tiết kiệm - linh hoạt',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Button
              CustomButton(
                text: 'Bắt đầu quản lý >',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

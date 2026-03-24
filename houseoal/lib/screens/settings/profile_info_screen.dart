import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants/colors.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen>
    with SingleTickerProviderStateMixin {
  final _infoFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isSavingInfo = false;
  bool _isSavingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _userId;
  String _avatarBase64 = '';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      _userId = await AuthService.getFirebaseUserId();
      if (_userId == null || _userId!.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = await FirestoreService.getUserById(_userId!);
      final sessionUser = await AuthService.getFirebaseUser();
      final data = userData ?? sessionUser ?? <String, dynamic>{};

      _nameController.text = (data['name'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      _phoneController.text = (data['phoneNumber'] ?? '').toString();
      _avatarBase64 = (data['avatarBase64'] ?? '').toString();
      _avatarUrl = (data['avatarUrl'] ?? '').toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatarFromDevice() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        imageQuality: 80,
      );
      if (xFile == null) return;

      final bytes = await xFile.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() {
        _avatarBase64 = base64Encode(bytes);
        _avatarUrl = '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn ảnh: $e')),
      );
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarBase64 = '';
      _avatarUrl = '';
    });
  }

  Future<void> _saveInfo() async {
    if (!_infoFormKey.currentState!.validate()) return;
    if (_userId == null || _userId!.isEmpty) return;

    setState(() => _isSavingInfo = true);
    try {
      final result = await FirestoreService.updateUserProfile(
        userId: _userId!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
        avatarBase64: _avatarBase64,
        currentPassword: '',
        newPassword: '',
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Cập nhật thất bại');
      }

      await AuthService.saveUserFirebase(
          result['user'] as Map<String, dynamic>);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông tin đã được cập nhật')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSavingInfo = false);
    }
  }

  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (_userId == null || _userId!.isEmpty) return;

    setState(() => _isSavingPassword = true);
    try {
      final result = await FirestoreService.updateUserProfile(
        userId: _userId!,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        avatarUrl: _avatarUrl,
        avatarBase64: _avatarBase64,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text.trim(),
      );

      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Đổi mật khẩu thất bại');
      }

      await AuthService.saveUserFirebase(
          result['user'] as Map<String, dynamic>);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu đã được đổi thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  Widget _buildAvatarPreview() {
    final hasBase64Image = _avatarBase64.trim().isNotEmpty;
    final hasNetworkImage =
        _avatarUrl.startsWith('http://') || _avatarUrl.startsWith('https://');
    final name = _nameController.text.trim();

    ImageProvider? imageProvider;
    if (hasBase64Image) {
      try {
        imageProvider = MemoryImage(base64Decode(_avatarBase64));
      } catch (_) {
        imageProvider = null;
      }
    }
    if (imageProvider == null && hasNetworkImage) {
      imageProvider = NetworkImage(_avatarUrl);
    }

    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.primary.withOpacity(0.14),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin người dùng'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Đổi mật khẩu'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildPasswordTab(),
              ],
            ),
    );
  }

  Widget _buildInfoTab() {
    return Form(
      key: _infoFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              children: [
                _buildAvatarPreview(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickAvatarFromDevice,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Tải ảnh từ máy'),
                    ),
                    if (_avatarBase64.isNotEmpty || _avatarUrl.isNotEmpty)
                      TextButton.icon(
                        onPressed: _removeAvatar,
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        label: const Text(
                          'Xóa ảnh',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              label: 'Họ và tên',
              icon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập tên';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              label: 'Email',
              icon: Icons.alternate_email_rounded,
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Vui lòng nhập email';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(text)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: 'Số điện thoại',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingInfo ? null : _saveInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSavingInfo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Lưu thông tin',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return Form(
      key: _passwordFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nhập mật khẩu hiện tại và mật khẩu mới để cập nhật.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            decoration: _inputDecoration(
              label: 'Mật khẩu hiện tại',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() =>
                    _obscureCurrentPassword = !_obscureCurrentPassword),
                icon: Icon(_obscureCurrentPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập mật khẩu hiện tại';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            decoration: _inputDecoration(
              label: 'Mật khẩu mới',
              icon: Icons.password_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(
                    () => _obscureNewPassword = !_obscureNewPassword),
                icon: Icon(_obscureNewPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Vui lòng nhập mật khẩu mới';
              if (text.length < 6) {
                return 'Mật khẩu mới cần ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: _inputDecoration(
              label: 'Xác nhận mật khẩu mới',
              icon: Icons.password_rounded,
              suffixIcon: IconButton(
                onPressed: () => setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword),
                icon: Icon(_obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
            ),
            validator: (value) {
              if (value != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingPassword ? null : _savePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSavingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:housepal/models/models.dart';
import 'dart:convert';

class AuthService {
  // Helper để convert DateTime thành String cho JSON
  static Map<String, dynamic> _prepareForJson(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is DateTime) {
        result[key] = value.toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _prepareForJson(value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  // Lưu người dùng hiện tại vào bộ nhớ local (cho Firebase - dùng String ID)
  static Future<void> saveUserFirebase(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final preparedData = _prepareForJson(userData);
    await prefs.setString('firebase_user', jsonEncode(preparedData));
    await prefs.setString('firebase_user_id', userData['id']?.toString() ?? '');
    await prefs.setString('firebase_user_name', userData['name'] ?? '');
    await prefs.setString('firebase_user_email', userData['email'] ?? '');
    await prefs.setString('firebase_house_id', userData['houseId'] ?? '');
  }

  // Lấy người dùng Firebase
  static Future<Map<String, dynamic>?> getFirebaseUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('firebase_user');
    if (userJson == null) return null;
    try {
      return jsonDecode(userJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Lấy Firebase user ID
  static Future<String?> getFirebaseUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_user_id');
  }

  // Lấy Firebase house ID
  static Future<String?> getFirebaseHouseId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('firebase_house_id');
  }

  // Cập nhật house ID sau khi join/create house
  static Future<void> updateFirebaseHouseId(String houseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firebase_house_id', houseId);
    
    // Cập nhật trong user object
    final userJson = prefs.getString('firebase_user');
    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      userData['houseId'] = houseId;
      await prefs.setString('firebase_user', jsonEncode(userData));
    }
  }

  // Lưu người dùng hiện tại vào bộ nhớ local (legacy - cho API backend)
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString('current_user', userJson);
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
  }

  // Lấy người dùng hiện tại từ bộ nhớ local
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Thử lấy từ Firebase user trước
    final firebaseUser = await getFirebaseUser();
    if (firebaseUser != null) {
      return User(
        id: 0, // Firebase dùng String ID, đặt 0 cho compatibility
        name: firebaseUser['name'] ?? '',
        email: firebaseUser['email'] ?? '',
        houseId: 0, // Sẽ dùng houseId string riêng
        chorePoints: (firebaseUser['chorePoints'] as num?)?.toInt() ?? 0,
        isAdmin: firebaseUser['isAdmin'] ?? false,
      );
    }

    // Fallback về legacy user
    final userJson = prefs.getString('current_user');
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(userJson);
      return User.fromJson(decoded);
    } catch (e) {
      print('Lỗi parse user: $e');
      return null;
    }
  }

  // Kiểm tra người dùng đã đăng nhập hay chưa
  static Future<bool> isUserLoggedIn() async {
    final firebaseUser = await getFirebaseUser();
    if (firebaseUser != null) return true;
    
    final user = await getCurrentUser();
    return user != null;
  }

  // Đăng xuất - xóa dữ liệu người dùng
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Firebase
    await prefs.remove('firebase_user');
    await prefs.remove('firebase_user_id');
    await prefs.remove('firebase_user_name');
    await prefs.remove('firebase_user_email');
    await prefs.remove('firebase_house_id');
    // Legacy
    await prefs.remove('current_user');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
  }

  // Lấy ID người dùng hiện tại
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Lấy tên người dùng hiện tại
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    // Firebase first
    final firebaseName = prefs.getString('firebase_user_name');
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;
    return prefs.getString('user_name');
  }

  // Lấy email người dùng hiện tại
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    // Firebase first
    final firebaseEmail = prefs.getString('firebase_user_email');
    if (firebaseEmail != null && firebaseEmail.isNotEmpty) return firebaseEmail;
    return prefs.getString('user_email');
  }
}

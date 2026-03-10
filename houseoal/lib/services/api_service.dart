import 'package:dio/dio.dart';
import 'package:housepal/models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.add(LoggingInterceptor());

  // ========== Houses ==========
  static Future<House> createHouse(String name, String description) async {
    try {
      final data = {
        'name': name,
        'description': description,
        'joinCode': _generateJoinCode(),
        'memberCount': 1,
      };
      final response = await _dio.post('/houses', data: data);
      return House.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo phòng: $e');
    }
  }
  
  static String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
    }
    return code;
  }

  static Future<List<House>> getHouses() async {
    try {
      final response = await _dio.get('/houses');
      final List<dynamic> data = response.data;
      return data.map((house) => House.fromJson(house)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách houses: $e');
    }
  }

  static Future<House> getHouseById(String id) async {
    try {
      final response = await _dio.get('/houses/$id');
      return House.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy house: $e');
    }
  }

  // Get house members by houseId
  static Future<List<User>> getHouseMembers(int houseId) async {
    try {
      final response = await _dio.get('/users');
      final List<dynamic> data = response.data;
      final allUsers = data.map((user) => User.fromJson(user)).toList();
      // Filter users belonging to this house
      return allUsers.where((user) => user.houseId == houseId).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách thành viên: $e');
    }
  }

  // ========== Users ==========
  static Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/users');
      final List<dynamic> data = response.data;
      return data.map((user) => User.fromJson(user)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách users: $e');
    }
  }

  static Future<User> getUser(String id) async {
    try {
      final response = await _dio.get('/users/$id');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy user: $e');
    }
  }

  static Future<User> createUser(User user) async {
    try {
      final response = await _dio.post('/users', data: user.toJson());
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo user: $e');
    }
  }

  // Generic POST request
  static Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw Exception('Lỗi: $e');
    }
  }

  // Verify login by email
  static Future<User> verifyLogin(String email) async {
    try {
      final response = await _dio.get('/users');
      final List<dynamic> data = response.data;
      
      // Filter user by email ở client side
      final userList = data.map((u) => User.fromJson(u)).toList();
      final user = userList.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('Email không tồn tại'),
      );
      return user;
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Join house by code - cập nhật houseId của user
  static Future<User> joinHouseByCode(int userId, String joinCode) async {
    try {
      // Lấy house theo join code
      final housesResponse = await _dio.get('/houses');
      final List<dynamic> housesData = housesResponse.data;
      
      final house = housesData.firstWhere(
        (h) => h['joinCode'] == joinCode,
        orElse: () => null,
      );
      
      if (house == null) {
        throw Exception('Mã phòng không hợp lệ');
      }
      
      // Lấy user hiện tại
      final usersResponse = await _dio.get('/users');
      final List<dynamic> usersData = usersResponse.data;
      final userMap = usersData.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => throw Exception('User không tồn tại'),
      );
      
      // Cập nhật houseId cho user
      userMap['houseId'] = house['id'];
      
      // Thử POST thay vì PUT (một số backend chỉ support POST)
      final response = await _dio.put('/users/$userId', data: userMap);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  static Future<User> updateUser(String id, User user) async {
    try {
      final response = await _dio.put('/users/$id', data: user.toJson());
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi cập nhật user: $e');
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/users/$id');
    } catch (e) {
      throw Exception('Lỗi xóa user: $e');
    }
  }

  // ========== Chores ==========
  static Future<List<Chore>> getChores({int? houseId}) async {
    try {
      final params = houseId != null ? {'houseId': houseId} : null;
      final response = await _dio.get('/chores', queryParameters: params);
      final List<dynamic> data = response.data;
      return data.map((chore) => Chore.fromJson(chore)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách chores: $e');
    }
  }

  static Future<Chore> getChoreById(String id) async {
    try {
      final response = await _dio.get('/chores/$id');
      return Chore.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy chore: $e');
    }
  }

  static Future<Chore> createChore(Chore chore) async {
    try {
      final response = await _dio.post('/chores', data: chore.toJson());
      return Chore.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo chore: $e');
    }
  }

  static Future<Chore> updateChore(String id, Chore chore) async {
    try {
      final response = await _dio.put('/chores/$id', data: chore.toJson());
      return Chore.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi cập nhật chore: $e');
    }
  }

  static Future<void> deleteChore(String id) async {
    try {
      await _dio.delete('/chores/$id');
    } catch (e) {
      throw Exception('Lỗi xóa chore: $e');
    }
  }

  // Assign chore to user
  static Future<void> assignChore(int choreId, int userId) async {
    try {
      await _dio.post('/chores/$choreId/assign', data: {'userId': userId});
    } catch (e) {
      throw Exception('Lỗi giao việc: $e');
    }
  }

  // Complete chore (only assigned user can complete)
  static Future<Map<String, dynamic>> completeChore(int choreId, int userId) async {
    try {
      final response = await _dio.post('/chores/$choreId/complete', data: {'userId': userId});
      return response.data;
    } catch (e) {
      throw Exception('Lỗi hoàn thành công việc: $e');
    }
  }

  // Get my assigned chores
  static Future<List<dynamic>> getMyChores(int userId) async {
    try {
      final response = await _dio.get('/chores/my/$userId');
      return response.data;
    } catch (e) {
      throw Exception('Lỗi lấy công việc của tôi: $e');
    }
  }

  // Get chore assignments
  static Future<List<dynamic>> getChoreAssignments(int choreId) async {
    try {
      final response = await _dio.get('/chores/$choreId/assignments');
      return response.data;
    } catch (e) {
      throw Exception('Lỗi lấy danh sách giao việc: $e');
    }
  }

  // ========== Expenses ==========
  static Future<List<Expense>> getExpenses({int? houseId}) async {
    try {
      final params = houseId != null ? {'houseId': houseId} : null;
      final response = await _dio.get('/expenses', queryParameters: params);
      final List<dynamic> data = response.data;
      return data.map((expense) => Expense.fromJson(expense)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách expenses: $e');
    }
  }

  static Future<Expense> getExpenseById(String id) async {
    try {
      final response = await _dio.get('/expenses/$id');
      return Expense.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy expense: $e');
    }
  }

  static Future<Expense> createExpense(Expense expense) async {
    try {
      final response = await _dio.post('/expenses', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo expense: $e');
    }
  }

  static Future<Expense> updateExpense(String id, Expense expense) async {
    try {
      final response = await _dio.put('/expenses/$id', data: expense.toJson());
      return Expense.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi cập nhật expense: $e');
    }
  }

  static Future<void> deleteExpense(String id) async {
    try {
      await _dio.delete('/expenses/$id');
    } catch (e) {
      throw Exception('Lỗi xóa expense: $e');
    }
  }

  // ========== Bulletin Notes ==========
  static Future<List<BulletinNote>> getBulletinNotes({int? houseId}) async {
    try {
      final params = houseId != null ? {'houseId': houseId} : null;
      final response = await _dio.get('/notes', queryParameters: params);
      final List<dynamic> data = response.data;
      return data.map((note) => BulletinNote.fromJson(note)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách notes: $e');
    }
  }

  static Future<BulletinNote> createBulletinNote(BulletinNote note) async {
    try {
      final response = await _dio.post('/notes', data: note.toJson());
      return BulletinNote.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo note: $e');
    }
  }

  static Future<void> deleteBulletinNote(String id) async {
    try {
      await _dio.delete('/notes/$id');
    } catch (e) {
      throw Exception('Lỗi xóa note: $e');
    }
  }

  // ========== Balance & Debt APIs ==========
  
  /// Lấy bảng cân đối nợ của house - "Ai nợ Ai"
  static Future<BalanceResponse> getHouseBalance(int houseId) async {
    try {
      final response = await _dio.get('/expenses/balance/$houseId');
      return BalanceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy balance: $e');
    }
  }

  /// Lấy balance của một user
  static Future<UserBalanceResponse> getUserBalance(int userId) async {
    try {
      final response = await _dio.get('/expenses/balance/user/$userId');
      return UserBalanceResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi lấy user balance: $e');
    }
  }

  /// Thanh toán nợ
  static Future<void> settleDebt(int debtId) async {
    try {
      await _dio.post('/expenses/settle', data: {'debtId': debtId});
    } catch (e) {
      throw Exception('Lỗi thanh toán nợ: $e');
    }
  }

  /// Thanh toán một phần nợ
  static Future<Map<String, dynamic>> settlePartialDebt(int debtId, double amount) async {
    try {
      final response = await _dio.post('/expenses/settle-partial', data: {
        'debtId': debtId,
        'amount': amount,
      });
      return response.data;
    } catch (e) {
      throw Exception('Lỗi thanh toán một phần: $e');
    }
  }

  /// Tạo chi tiêu với phân chia
  static Future<Expense> createExpenseWithSplit({
    required int houseId,
    required int paidByUserId,
    required String description,
    required double amount,
    String? category,
    String splitType = 'equal',
    List<Map<String, dynamic>>? customSplits,
    List<int>? selectedUserIds,
  }) async {
    try {
      final data = {
        'houseId': houseId,
        'paidByUserId': paidByUserId,
        'description': description,
        'amount': amount,
        'category': category ?? 'other',
        'splitType': splitType,
      };

      if (customSplits != null) {
        data['customSplits'] = customSplits;
      }
      if (selectedUserIds != null) {
        data['selectedUserIds'] = selectedUserIds;
      }

      final response = await _dio.post('/expenses', data: data);
      return Expense.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo expense: $e');
    }
  }

  // ========== Shopping Items ==========
  static Future<List<ShoppingItem>> getShoppingItems({int? houseId}) async {
    try {
      final params = houseId != null ? {'houseId': houseId} : null;
      final response = await _dio.get('/shopping', queryParameters: params);
      final List<dynamic> data = response.data;
      return data.map((item) => ShoppingItem.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách shopping items: $e');
    }
  }

  static Future<ShoppingItem> createShoppingItem(ShoppingItem item) async {
    try {
      final response = await _dio.post('/shopping', data: item.toJson());
      return ShoppingItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi tạo shopping item: $e');
    }
  }

  static Future<ShoppingItem> updateShoppingItem(String id, ShoppingItem item) async {
    try {
      final response = await _dio.put('/shopping/$id', data: item.toJson());
      return ShoppingItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi cập nhật shopping item: $e');
    }
  }

  static Future<void> deleteShoppingItem(String id) async {
    try {
      await _dio.delete('/shopping/$id');
    } catch (e) {
      throw Exception('Lỗi xóa shopping item: $e');
    }
  }

  static Future<ShoppingItem> markAsPurchased(String id) async {
    try {
      final response = await _dio.post('/shopping/$id/purchased');
      return ShoppingItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Lỗi đánh dấu đã mua: $e');
    }
  }
}

class LoggingInterceptor extends QueuedInterceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('📤 [REQUEST] ${options.method} ${options.path}');
    print('   Headers: ${options.headers}');
    print('   Data: ${options.data}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('📥 [RESPONSE] ${response.statusCode} - ${response.data}');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ [ERROR] ${err.type}');
    print('   Response: ${err.response?.statusCode} - ${err.response?.data}');
    print('   Message: ${err.message}');
    return handler.next(err);
  }
}

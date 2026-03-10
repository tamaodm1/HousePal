import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Helper để hash password
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Helper để convert Timestamp thành DateTime
  static Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertTimestamps(value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  // ============ USERS ============
  
  static Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    await _db.collection('users').doc(userId).set({
      ...userData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.data() != null) {
      return _convertTimestamps({'id': doc.id, ...doc.data()!});
    }
    return null;
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ HOUSES ============
  
  static Future<String> createHouse(Map<String, dynamic> houseData) async {
    final docRef = await _db.collection('houses').add({
      ...houseData,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<Map<String, dynamic>?> getHouse(String houseId) async {
    final doc = await _db.collection('houses').doc(houseId).get();
    if (doc.exists) {
      return _convertTimestamps({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  // Alias cho getHouse để dùng chung
  static Future<Map<String, dynamic>?> getHouseById(String houseId) async {
    return await getHouse(houseId);
  }

  // Set owner cho house (dùng khi house cũ chưa có ownerId)
  static Future<void> setHouseOwner(String houseId, String userId) async {
    await _db.collection('houses').doc(houseId).update({
      'ownerId': userId,
    });
  }

  static Future<List<Map<String, dynamic>>> getHousesByJoinCode(String joinCode) async {
    final query = await _db
        .collection('houses')
        .where('joinCode', isEqualTo: joinCode)
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  static Stream<List<Map<String, dynamic>>> streamHouses() {
    return _db.collection('houses').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => _convertTimestamps({
          'id': doc.id,
          ...doc.data(),
        }))
        .toList());
  }

  static Future<void> updateHouse(String houseId, Map<String, dynamic> data) async {
    await _db.collection('houses').doc(houseId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ CHORES ============
  
  static Future<String> createChore(Map<String, dynamic> choreData) async {
    final docRef = await _db.collection('chores').add({
      ...choreData,
      'isCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<Map<String, dynamic>?> getChore(String choreId) async {
    final doc = await _db.collection('chores').doc(choreId).get();
    if (doc.exists) {
      return _convertTimestamps({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  static Stream<List<Map<String, dynamic>>> streamChoresByHouse(String houseId) {
    return _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  // Get chores by house (non-stream - cho dashboard)
  static Future<List<Map<String, dynamic>>> getChoresByHouse(String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  static Future<void> updateChore(String choreId, Map<String, dynamic> data) async {
    await _db.collection('chores').doc(choreId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteChore(String choreId) async {
    await _db.collection('chores').doc(choreId).delete();
  }

  // ============ EXPENSES ============
  
  static Future<String> createExpense(Map<String, dynamic> expenseData) async {
    final docRef = await _db.collection('expenses').add({
      ...expenseData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<Map<String, dynamic>?> getExpense(String expenseId) async {
    final doc = await _db.collection('expenses').doc(expenseId).get();
    if (doc.exists) {
      return _convertTimestamps({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  static Stream<List<Map<String, dynamic>>> streamExpensesByHouse(String houseId) {
    return _db
        .collection('expenses')
        .where('houseId', isEqualTo: houseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  // Get expenses by house (non-stream - cho dashboard)
  static Future<List<Map<String, dynamic>>> getExpensesByHouse(String houseId) async {
    final query = await _db
        .collection('expenses')
        .where('houseId', isEqualTo: houseId)
        .get();
    final results = query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
    // Sắp xếp theo ngày tạo mới nhất
    results.sort((a, b) {
      final aDate = a['createdAt']?.toString() ?? '';
      final bDate = b['createdAt']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    return results;
  }

  static Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    await _db.collection('expenses').doc(expenseId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteExpense(String expenseId) async {
    await _db.collection('expenses').doc(expenseId).delete();
  }

  // ============ BULLETIN NOTES ============
  
  static Future<String> createNote(Map<String, dynamic> noteData) async {
    final docRef = await _db.collection('notes').add({
      ...noteData,
      'isPinned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> streamNotesByHouse(String houseId) {
    return _db
        .collection('notes')
        .where('houseId', isEqualTo: houseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  // Get notes by house (non-stream - cho dashboard)
  static Future<List<Map<String, dynamic>>> getNotesByHouse(String houseId) async {
    final query = await _db
        .collection('notes')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  static Future<void> updateNote(String noteId, Map<String, dynamic> data) async {
    await _db.collection('notes').doc(noteId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNote(String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }

  // ============ SHOPPING ITEMS ============
  
  static Future<String> createShoppingItem(Map<String, dynamic> itemData) async {
    final docRef = await _db.collection('shopping_items').add({
      ...itemData,
      'isPurchased': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> streamShoppingItemsByHouse(String houseId) {
    return _db
        .collection('shopping_items')
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  static Future<void> updateShoppingItem(String itemId, Map<String, dynamic> data) async {
    await _db.collection('shopping_items').doc(itemId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteShoppingItem(String itemId) async {
    await _db.collection('shopping_items').doc(itemId).delete();
  }

  // Get shopping items by house (non-stream)
  static Future<List<Map<String, dynamic>>> getShoppingItemsByHouse(String houseId) async {
    final query = await _db
        .collection('shopping_items')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  // ============ CHORE ASSIGNMENTS ============

  static Future<String> assignChore(String choreId, String userId, String userName) async {
    final docRef = await _db.collection('chore_assignments').add({
      'choreId': choreId,
      'userId': userId,
      'userName': userName,
      'completedAt': null,
      'assignedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<List<Map<String, dynamic>>> getChoreAssignments(String choreId) async {
    final query = await _db
        .collection('chore_assignments')
        .where('choreId', isEqualTo: choreId)
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  // ============ HELPERS: DAILY RESET ============

  static String _todayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  static bool _shouldResetChore(String frequency, String? lastResetDate) {
    if (lastResetDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime.parse(lastResetDate);
    switch (frequency) {
      case 'daily':
        return lastReset.isBefore(today);
      case 'weekly':
        return today.difference(lastReset).inDays >= 7;
      case 'monthly':
        return today.month != lastReset.month || today.year != lastReset.year;
      default:
        return lastReset.isBefore(today);
    }
  }

  /// Kiểm tra & reset việc xoay vòng khi qua ngày mới
  /// - Nếu chưa hoàn thành → trừ điểm người được giao
  /// - Luân phiên sang người tiếp theo
  static Future<void> checkAndResetChores(String houseId) async {
    final todayStr = _todayString();
    final chores = await getRecurringChores(houseId);

    for (var chore in chores) {
      final choreId = chore['id'] as String;
      final frequency = chore['frequency'] ?? 'daily';
      final lastResetDate = chore['lastResetDate'] as String?;

      // Chore cũ chưa có lastResetDate → set lần đầu, không phạt
      if (lastResetDate == null) {
        await _db.collection('chores').doc(choreId).update({
          'lastResetDate': todayStr,
        });
        continue;
      }

      // Chưa cần reset (vẫn trong cùng kỳ)
      if (!_shouldResetChore(frequency, lastResetDate)) continue;

      final lastCompletedDate = chore['lastCompletedDate'] as String?;
      final currentAssigneeId = chore['currentAssigneeId'] as String?;
      final points = chore['points'] ?? 10;
      final assignmentOrder = List<String>.from(chore['assignmentOrder'] ?? []);
      final currentIndex = chore['currentAssigneeIndex'] ?? 0;

      // Kiểm tra kỳ trước có hoàn thành không
      bool wasCompleted = lastCompletedDate != null && lastCompletedDate == lastResetDate;

      // KHÔNG hoàn thành → TRỪ ĐIỂM
      if (!wasCompleted && currentAssigneeId != null && currentAssigneeId.isNotEmpty) {
        await _db.collection('users').doc(currentAssigneeId).update({
          'chorePoints': FieldValue.increment(-points),
        });
      }

      // LUÂN PHIÊN sang người tiếp theo
      if (assignmentOrder.isNotEmpty) {
        final nextIndex = (currentIndex + 1) % assignmentOrder.length;
        final nextUserId = assignmentOrder[nextIndex];
        final nextUserDoc = await _db.collection('users').doc(nextUserId).get();
        final nextUserName = nextUserDoc.data()?['name'] ?? 'Unknown';

        await _db.collection('chores').doc(choreId).update({
          'currentAssigneeIndex': nextIndex,
          'currentAssigneeId': nextUserId,
          'currentAssigneeName': nextUserName,
          'lastResetDate': todayStr,
          'lastCompletedDate': null,
        });
      } else {
        await _db.collection('chores').doc(choreId).update({
          'lastResetDate': todayStr,
          'lastCompletedDate': null,
        });
      }
    }
  }

  static Future<void> completeChore(String choreId, String userId) async {
    final choreDoc = await _db.collection('chores').doc(choreId).get();
    if (!choreDoc.exists) return;

    final choreData = choreDoc.data()!;
    final choreType = choreData['type'] ?? 'recurring';
    final points = choreData['points'] ?? 10;

    if (choreType == 'recurring') {
      final todayStr = _todayString();

      // Đã hoàn thành hôm nay rồi
      if (choreData['lastCompletedDate'] == todayStr) {
        throw Exception('Việc này đã hoàn thành hôm nay rồi!');
      }

      // Kiểm tra đúng người được giao
      if (choreData['currentAssigneeId'] != userId) {
        throw Exception('Chưa đến lượt bạn!');
      }

      // Đánh dấu hoàn thành hôm nay (KHÔNG luân phiên - chờ qua 0h)
      await _db.collection('chores').doc(choreId).update({
        'lastCompletedDate': todayStr,
        'lastCompletedByUserId': userId,
        'lastCompletedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // VIỆC TỰ NHẬN: Đánh dấu hoàn thành
      await _db.collection('chores').doc(choreId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completedByUserId': userId,
      });
    }

    // Tăng điểm cho user
    await _db.collection('users').doc(userId).update({
      'chorePoints': FieldValue.increment(points),
    });
  }

  // ============ VIỆC XOAY VÒNG (Recurring Chores) ============
  
  /// Tạo việc xoay vòng - tự động giao luân phiên
  static Future<String> createRecurringChore({
    required String houseId,
    required String title,
    required String description,
    required String frequency, // daily, weekly, monthly
    required int points,
  }) async {
    // Lấy danh sách thành viên để tạo thứ tự xoay vòng
    final members = await getHouseMembers(houseId);
    final assignmentOrder = members.map((m) => m['id'] as String).toList();
    
    final firstUserId = assignmentOrder.isNotEmpty ? assignmentOrder[0] : '';
    final firstUserName = members.isNotEmpty ? (members[0]['name'] ?? 'Unknown') : '';
    
    final todayStr = _todayString();
    final docRef = await _db.collection('chores').add({
      'houseId': houseId,
      'title': title,
      'description': description,
      'type': 'recurring',
      'frequency': frequency,
      'points': points,
      'assignmentOrder': assignmentOrder,
      'currentAssigneeIndex': 0,
      'currentAssigneeId': firstUserId,
      'currentAssigneeName': firstUserName,
      'lastResetDate': todayStr,
      'lastCompletedDate': null,
      'lastCompletedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ============ VIỆC TỰ NHẬN (One-time Chores) ============
  
  /// Tạo việc tự nhận - ai muốn làm thì nhận
  static Future<String> createOneTimeChore({
    required String houseId,
    required String title,
    required String description,
    required int points,
  }) async {
    final docRef = await _db.collection('chores').add({
      'houseId': houseId,
      'title': title,
      'description': description,
      'type': 'one-time',
      'points': points,
      'status': 'available', // available, claimed, completed
      'claimedByUserId': null,
      'claimedByUserName': null,
      'claimedAt': null,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Nhận việc (cho one-time chores)
  static Future<void> claimChore(String choreId, String userId, String userName) async {
    await _db.collection('chores').doc(choreId).update({
      'status': 'claimed',
      'claimedByUserId': userId,
      'claimedByUserName': userName,
      'claimedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy việc xoay vòng của house
  static Future<List<Map<String, dynamic>>> getRecurringChores(String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .where('type', isEqualTo: 'recurring')
        .get();
    return query.docs.map((doc) => _convertTimestamps({
      'id': doc.id,
      ...doc.data(),
    })).toList();
  }

  /// Lấy việc tự nhận của house (chưa hoàn thành)
  static Future<List<Map<String, dynamic>>> getOneTimeChores(String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .where('type', isEqualTo: 'one-time')
        .get();
    // Lọc bỏ các việc đã completed
    final chores = query.docs
        .map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()}))
        .where((c) => c['status'] != 'completed')
        .toList();
    return chores;
  }

  /// Lấy việc đã hoàn thành của house
  static Future<List<Map<String, dynamic>>> getCompletedChores(String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .where('type', isEqualTo: 'one-time')
        .get();
    final oneTimeCompleted = query.docs
        .map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()}))
        .where((c) => c['status'] == 'completed')
        .toList();
    return oneTimeCompleted;
  }

  // ============ BALANCES (for splits) ============
  
  static Future<String> createBalance(Map<String, dynamic> balanceData) async {
    final docRef = await _db.collection('balances').add({
      ...balanceData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> streamBalancesByHouse(String houseId) {
    return _db
        .collection('balances')
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  static Future<void> updateBalance(String balanceId, Map<String, dynamic> data) async {
    await _db.collection('balances').doc(balanceId).update(data);
  }

  // ============ DEBTS ============

  static Future<String> createDebt(Map<String, dynamic> debtData) async {
    final docRef = await _db.collection('debts').add({
      ...debtData,
      'isSettled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> streamDebtsByHouse(String houseId) {
    return _db
        .collection('debts')
        .where('houseId', isEqualTo: houseId)
        .where('isSettled', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
            .toList());
  }

  static Future<List<Map<String, dynamic>>> getDebtsByHouse(String houseId) async {
    final query = await _db
        .collection('debts')
        .where('houseId', isEqualTo: houseId)
        .where('isSettled', isEqualTo: false)
        .get();
    return query.docs.map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()})).toList();
  }

  static Future<List<Map<String, dynamic>>> getDebtsByUser(String userId) async {
    // Lấy nợ mà user này nợ người khác
    final owesQuery = await _db
        .collection('debts')
        .where('debtorId', isEqualTo: userId)
        .where('isSettled', isEqualTo: false)
        .get();
    
    // Lấy nợ mà người khác nợ user này
    final owedQuery = await _db
        .collection('debts')
        .where('creditorId', isEqualTo: userId)
        .where('isSettled', isEqualTo: false)
        .get();
    
    final debts = [
      ...owesQuery.docs.map((doc) => _convertTimestamps({'id': doc.id, 'type': 'owes', ...doc.data()})),
      ...owedQuery.docs.map((doc) => _convertTimestamps({'id': doc.id, 'type': 'owed', ...doc.data()})),
    ];
    return debts;
  }

  static Future<void> settleDebt(String debtId) async {
    await _db.collection('debts').doc(debtId).update({
      'isSettled': true,
      'settledAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateDebtAmount(String debtId, double newAmount) async {
    await _db.collection('debts').doc(debtId).update({
      'amount': newAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ EXPENSE WITH SPLIT (tạo expense + debts) ============

  static Future<void> createExpenseWithSplit({
    required String houseId,
    required String paidByUserId,
    required String paidByName,
    required String description,
    required double amount,
    required String category,
    required List<Map<String, dynamic>> splitWith, // [{userId, userName, amount}]
  }) async {
    // 1. Tạo expense
    final expenseId = await createExpense({
      'houseId': houseId,
      'paidByUserId': paidByUserId,
      'paidByName': paidByName,
      'description': description,
      'amount': amount,
      'category': category,
      'splitType': 'equal',
    });

    // 2. Tạo debts cho mỗi người được chia (trừ người trả)
    for (var split in splitWith) {
      if (split['userId'] != paidByUserId && split['amount'] > 0) {
        await createDebt({
          'houseId': houseId,
          'expenseId': expenseId,
          'debtorId': split['userId'],
          'debtorName': split['userName'],
          'creditorId': paidByUserId,
          'creditorName': paidByName,
          'amount': split['amount'],
          'description': description,
        });
      }
    }
  }

  // ============ GET HOUSE MEMBERS ============

  static Future<List<Map<String, dynamic>>> getHouseMembers(String houseId) async {
    final query = await _db
        .collection('users')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs.map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()})).toList();
  }

  // ============ AUTH (Login/Register using Firestore) ============

  /// Đăng ký user mới
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      // Kiểm tra email đã tồn tại chưa
      final existingUsers = await _db
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email đã được sử dụng',
        };
      }

      // Tạo user mới với password đã hash
      final hashedPassword = _hashPassword(password);
      final docRef = await _db.collection('users').add({
        'name': name,
        'email': email.toLowerCase(),
        'phoneNumber': phoneNumber,
        'password': hashedPassword,
        'houseId': '',
        'chorePoints': 0,
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'user': {
          'id': docRef.id,
          'name': name,
          'email': email.toLowerCase(),
          'phoneNumber': phoneNumber,
          'houseId': '',
          'chorePoints': 0,
          'isAdmin': false,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi đăng ký: $e',
      };
    }
  }

  /// Đăng nhập bằng email
  static Future<Map<String, dynamic>> loginByEmail(String email, String password) async {
    try {
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (query.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Email không tồn tại',
        };
      }

      final userData = query.docs.first.data();
      final storedPassword = userData['password'] as String?;
      
      // Kiểm tra password - hỗ trợ cả password cũ (không hash) và mới (đã hash)
      final hashedInputPassword = _hashPassword(password);
      final isPasswordCorrect = storedPassword == password || storedPassword == hashedInputPassword;
      
      if (storedPassword != null && !isPasswordCorrect) {
        return {
          'success': false,
          'message': 'Mật khẩu không đúng',
        };
      }
      
      // Nếu password cũ chưa hash, tự động cập nhật sang hash
      if (storedPassword == password && storedPassword != hashedInputPassword) {
        await _db.collection('users').doc(query.docs.first.id).update({
          'password': hashedInputPassword,
        });
      }

      return {
        'success': true,
        'user': _convertTimestamps({
          'id': query.docs.first.id,
          ...userData,
        }),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi đăng nhập: $e',
      };
    }
  }

  /// Lấy user theo ID
  static Future<Map<String, dynamic>?> getUserById(String oduserId) async {
    final doc = await _db.collection('users').doc(oduserId).get();
    if (doc.exists) {
      return _convertTimestamps({'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  /// Cập nhật houseId cho user (khi join house)
  static Future<void> updateUserHouse(String userId, String houseId) async {
    await _db.collection('users').doc(userId).update({
      'houseId': houseId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tạo house mới
  static Future<Map<String, dynamic>> createHouseAndJoin({
    required String houseName,
    required String description,
    required String userId,
  }) async {
    // Tạo mã join ngẫu nhiên
    final joinCode = _generateJoinCode();
    
    // Tạo house
    final houseRef = await _db.collection('houses').add({
      'name': houseName,
      'description': description,
      'joinCode': joinCode,
      'ownerId': userId,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Cập nhật houseId cho user
    await updateUserHouse(userId, houseRef.id);

    return {
      'success': true,
      'houseId': houseRef.id,
      'name': houseName,
      'description': description,
      'joinCode': joinCode,
      'memberCount': 1,
    };
  }

  /// Tham gia house bằng mã code
  static Future<Map<String, dynamic>> joinHouseByCode({
    required String joinCode,
    required String userId,
  }) async {
    final query = await _db
        .collection('houses')
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .get();
    
    if (query.docs.isEmpty) {
      return {
        'success': false,
        'message': 'Mã phòng không hợp lệ',
      };
    }

    final house = query.docs.first;
    final houseData = house.data();
    
    // Cập nhật houseId cho user
    await updateUserHouse(userId, house.id);
    
    // Tăng memberCount
    await _db.collection('houses').doc(house.id).update({
      'memberCount': FieldValue.increment(1),
    });

    return {
      'success': true,
      'houseId': house.id,
      ...houseData,
    };
  }

  static String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    return code;
  }
}

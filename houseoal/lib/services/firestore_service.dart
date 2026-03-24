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

  // ============ NOTIFICATIONS ============

  static Future<void> createNotification({
    required String recipientUserId,
    required String houseId,
    required String title,
    required String message,
    String type = 'info', // chore, expense, debt, info
    String? relatedId,
  }) async {
    await _db.collection('notifications').add({
      'recipientUserId': recipientUserId,
      'houseId': houseId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getNotificationsByUser(
      String userId) async {
    final query = await _db
        .collection('notifications')
        .where('recipientUserId', isEqualTo: userId)
        .get();
    final items = query.docs
        .map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()}))
        .toList();
    items.sort((a, b) {
      final aDate = a['createdAt']?.toString() ?? '';
      final bDate = b['createdAt']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    return items;
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ USERS ============

  static Future<void> createUser(
      String userId, Map<String, dynamic> userData) async {
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

  static Future<void> updateUser(
      String userId, Map<String, dynamic> data) async {
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
      return _convertTimestamps(
          {'id': doc.id, ...doc.data() as Map<String, dynamic>});
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

  static Future<List<Map<String, dynamic>>> getHousesByJoinCode(
      String joinCode) async {
    final query = await _db
        .collection('houses')
        .where('joinCode', isEqualTo: joinCode)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  static Stream<List<Map<String, dynamic>>> streamHouses() {
    return _db.collection('houses').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList());
  }

  static Future<void> updateHouse(
      String houseId, Map<String, dynamic> data) async {
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
      return _convertTimestamps(
          {'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  static Stream<List<Map<String, dynamic>>> streamChoresByHouse(
      String houseId) {
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
  static Future<List<Map<String, dynamic>>> getChoresByHouse(
      String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  static Future<void> updateChore(
      String choreId, Map<String, dynamic> data) async {
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
      return _convertTimestamps(
          {'id': doc.id, ...doc.data() as Map<String, dynamic>});
    }
    return null;
  }

  static Stream<List<Map<String, dynamic>>> streamExpensesByHouse(
      String houseId) {
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
  static Future<List<Map<String, dynamic>>> getExpensesByHouse(
      String houseId) async {
    final query = await _db
        .collection('expenses')
        .where('houseId', isEqualTo: houseId)
        .get();
    final results = query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
    // Sắp xếp theo ngày tạo mới nhất
    results.sort((a, b) {
      final aDate = a['createdAt']?.toString() ?? '';
      final bDate = b['createdAt']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    return results;
  }

  static Future<void> updateExpense(
      String expenseId, Map<String, dynamic> data) async {
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
  static Future<List<Map<String, dynamic>>> getNotesByHouse(
      String houseId) async {
    final query = await _db
        .collection('notes')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  static Future<void> updateNote(
      String noteId, Map<String, dynamic> data) async {
    await _db.collection('notes').doc(noteId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteNote(String noteId) async {
    await _db.collection('notes').doc(noteId).delete();
  }

  // ============ SHOPPING ITEMS ============

  static Future<String> createShoppingItem(
      Map<String, dynamic> itemData) async {
    final docRef = await _db.collection('shopping_items').add({
      ...itemData,
      'isPurchased': false,
      'addedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Stream<List<Map<String, dynamic>>> streamShoppingItemsByHouse(
      String houseId) {
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

  static Future<void> updateShoppingItem(
      String itemId, Map<String, dynamic> data) async {
    await _db.collection('shopping_items').doc(itemId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteShoppingItem(String itemId) async {
    await _db.collection('shopping_items').doc(itemId).delete();
  }

  // Get shopping items by house (non-stream)
  static Future<List<Map<String, dynamic>>> getShoppingItemsByHouse(
      String houseId) async {
    final query = await _db
        .collection('shopping_items')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  // ============ CHORE ASSIGNMENTS ============

  static Future<String> assignChore(
      String choreId, String userId, String userName) async {
    final docRef = await _db.collection('chore_assignments').add({
      'choreId': choreId,
      'userId': userId,
      'userName': userName,
      'completedAt': null,
      'assignedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  static Future<List<Map<String, dynamic>>> getChoreAssignments(
      String choreId) async {
    final query = await _db
        .collection('chore_assignments')
        .where('choreId', isEqualTo: choreId)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
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
      bool wasCompleted =
          lastCompletedDate != null && lastCompletedDate == lastResetDate;

      // KHÔNG hoàn thành → TRỪ ĐIỂM
      if (!wasCompleted &&
          currentAssigneeId != null &&
          currentAssigneeId.isNotEmpty) {
        await _db.collection('users').doc(currentAssigneeId).update({
          'chorePoints': FieldValue.increment(-points),
        });
        await createNotification(
          recipientUserId: currentAssigneeId,
          houseId: houseId,
          title: 'Bạn bị trừ điểm',
          message:
              'Bạn chưa hoàn thành "${chore['title'] ?? 'việc nhà'}" đúng hạn (-$points điểm).',
          type: 'chore',
          relatedId: choreId,
        );
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

        await createNotification(
          recipientUserId: nextUserId,
          houseId: houseId,
          title: 'Đến lượt việc nhà',
          message: 'Đến lượt bạn làm "${chore['title'] ?? 'việc nhà'}".',
          type: 'chore',
          relatedId: choreId,
        );
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
    final firstUserName =
        members.isNotEmpty ? (members[0]['name'] ?? 'Unknown') : '';

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
  static Future<void> claimChore(
      String choreId, String userId, String userName) async {
    await _db.collection('chores').doc(choreId).update({
      'status': 'claimed',
      'claimedByUserId': userId,
      'claimedByUserName': userName,
      'claimedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Lấy việc xoay vòng của house
  static Future<List<Map<String, dynamic>>> getRecurringChores(
      String houseId) async {
    final query = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .where('type', isEqualTo: 'recurring')
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();
  }

  /// Lấy việc tự nhận của house (chưa hoàn thành)
  static Future<List<Map<String, dynamic>>> getOneTimeChores(
      String houseId) async {
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
  static Future<List<Map<String, dynamic>>> getCompletedChores(
      String houseId) async {
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

  static Stream<List<Map<String, dynamic>>> streamBalancesByHouse(
      String houseId) {
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

  static Future<void> updateBalance(
      String balanceId, Map<String, dynamic> data) async {
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

  static Future<List<Map<String, dynamic>>> getDebtsByHouse(
      String houseId) async {
    final query = await _db
        .collection('debts')
        .where('houseId', isEqualTo: houseId)
        .where('isSettled', isEqualTo: false)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()}))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getDebtsByUser(
      String userId) async {
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
      ...owesQuery.docs.map((doc) =>
          _convertTimestamps({'id': doc.id, 'type': 'owes', ...doc.data()})),
      ...owedQuery.docs.map((doc) =>
          _convertTimestamps({'id': doc.id, 'type': 'owed', ...doc.data()})),
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

  /// Tạo khoản nợ mới nhưng tự động NET với khoản nợ ngược chiều đang tồn tại.
  /// Ví dụ: A nợ B 50k, tạo thêm B nợ A 20k -> còn A nợ B 30k.
  static Future<void> _createOrNetDebt({
    required String houseId,
    required String expenseId,
    required String debtorId,
    required String debtorName,
    required String creditorId,
    required String creditorName,
    required double amount,
    required String description,
  }) async {
    if (amount <= 0) return;

    double remaining = amount;

    final oppositeQuery = await _db
        .collection('debts')
        .where('houseId', isEqualTo: houseId)
        .where('debtorId', isEqualTo: creditorId)
        .where('creditorId', isEqualTo: debtorId)
        .where('isSettled', isEqualTo: false)
        .get();

    for (final doc in oppositeQuery.docs) {
      if (remaining <= 0) break;

      final data = doc.data();
      final oppositeAmount = (data['amount'] as num?)?.toDouble() ?? 0;
      if (oppositeAmount <= 0) continue;

      if (oppositeAmount > remaining) {
        await _db.collection('debts').doc(doc.id).update({
          'amount': oppositeAmount - remaining,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        remaining = 0;
      } else if (oppositeAmount == remaining) {
        await settleDebt(doc.id);
        remaining = 0;
      } else {
        await settleDebt(doc.id);
        remaining -= oppositeAmount;
      }
    }

    if (remaining > 0) {
      await createDebt({
        'houseId': houseId,
        'expenseId': expenseId,
        'debtorId': debtorId,
        'debtorName': debtorName,
        'creditorId': creditorId,
        'creditorName': creditorName,
        'amount': remaining,
        'description': description,
      });
    }
  }

  /// Tính danh sách nợ tối giản theo số dư ròng toàn house (không ghi DB).
  static Future<List<Map<String, dynamic>>> getSimplifiedDebtsByHouse(
      String houseId) async {
    final rawDebts = await getDebtsByHouse(houseId);
    if (rawDebts.isEmpty) return [];

    final Map<String, double> net = {}; // + là được nhận, - là phải trả
    final Map<String, String> names = {};

    for (final debt in rawDebts) {
      final debtorId = (debt['debtorId'] ?? '').toString();
      final creditorId = (debt['creditorId'] ?? '').toString();
      final debtorName = (debt['debtorName'] ?? 'Unknown').toString();
      final creditorName = (debt['creditorName'] ?? 'Unknown').toString();
      final amount = (debt['amount'] as num?)?.toDouble() ?? 0;
      if (debtorId.isEmpty || creditorId.isEmpty || amount <= 0) continue;

      names[debtorId] = debtorName;
      names[creditorId] = creditorName;

      net[debtorId] = (net[debtorId] ?? 0) - amount;
      net[creditorId] = (net[creditorId] ?? 0) + amount;
    }

    final debtors = net.entries
        .where((e) => e.value < -0.0001)
        .map((e) => {'userId': e.key, 'amount': -e.value})
        .toList()
      ..sort(
          (a, b) => ((b['amount'] as double)).compareTo(a['amount'] as double));

    final creditors = net.entries
        .where((e) => e.value > 0.0001)
        .map((e) => {'userId': e.key, 'amount': e.value})
        .toList()
      ..sort(
          (a, b) => ((b['amount'] as double)).compareTo(a['amount'] as double));

    int i = 0, j = 0;
    final List<Map<String, dynamic>> simplified = [];

    while (i < debtors.length && j < creditors.length) {
      final debtorAmount = debtors[i]['amount'] as double;
      final creditorAmount = creditors[j]['amount'] as double;
      final transfer =
          debtorAmount < creditorAmount ? debtorAmount : creditorAmount;

      final debtorId = debtors[i]['userId'] as String;
      final creditorId = creditors[j]['userId'] as String;

      if (transfer > 0.0001) {
        simplified.add({
          'houseId': houseId,
          'debtorId': debtorId,
          'debtorName': names[debtorId] ?? 'Unknown',
          'creditorId': creditorId,
          'creditorName': names[creditorId] ?? 'Unknown',
          'amount': double.parse(transfer.toStringAsFixed(2)),
          'description': 'Nợ đã tối giản',
          'isSimplified': true,
        });
      }

      debtors[i]['amount'] = debtorAmount - transfer;
      creditors[j]['amount'] = creditorAmount - transfer;

      if ((debtors[i]['amount'] as double) <= 0.0001) i++;
      if ((creditors[j]['amount'] as double) <= 0.0001) j++;
    }

    return simplified;
  }

  // ============ EXPENSE WITH SPLIT (tạo expense + debts) ============

  static Future<void> createExpenseWithSplit({
    required String houseId,
    required String paidByUserId,
    required String paidByName,
    required String description,
    required double amount,
    required String category,
    String splitType = 'equal',
    required List<Map<String, dynamic>>
        splitWith, // [{userId, userName, amount}]
  }) async {
    // 1. Tạo expense
    final expenseId = await createExpense({
      'houseId': houseId,
      'paidByUserId': paidByUserId,
      'paidByName': paidByName,
      'description': description,
      'amount': amount,
      'category': category,
      'splitType': splitType,
    });

    // 2. Tạo debts cho mỗi người được chia (trừ người trả)
    for (var split in splitWith) {
      if (split['userId'] != paidByUserId && split['amount'] > 0) {
        await _createOrNetDebt(
          houseId: houseId,
          expenseId: expenseId,
          debtorId: split['userId'],
          debtorName: split['userName'],
          creditorId: paidByUserId,
          creditorName: paidByName,
          amount: (split['amount'] as num).toDouble(),
          description: description,
        );

        await createNotification(
          recipientUserId: split['userId'] as String,
          houseId: houseId,
          title: 'Khoản chi mới',
          message:
              '$paidByName vừa thêm "$description". Bạn cần trả ${(split['amount'] as num).toStringAsFixed(0)}đ.',
          type: 'expense',
          relatedId: expenseId,
        );
      }
    }

    await createNotification(
      recipientUserId: paidByUserId,
      houseId: houseId,
      title: 'Đã thêm chi tiêu',
      message: 'Khoản "$description" đã được ghi nhận thành công.',
      type: 'expense',
      relatedId: expenseId,
    );
  }

  // ============ GET HOUSE MEMBERS ============

  static Future<List<Map<String, dynamic>>> getHouseMembers(
      String houseId) async {
    final query = await _db
        .collection('users')
        .where('houseId', isEqualTo: houseId)
        .get();
    return query.docs
        .map((doc) => _convertTimestamps({'id': doc.id, ...doc.data()}))
        .toList();
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
  static Future<Map<String, dynamic>> loginByEmail(
      String email, String password) async {
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
      final isPasswordCorrect =
          storedPassword == password || storedPassword == hashedInputPassword;

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

  /// Cập nhật hồ sơ người dùng hiện tại
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    String? phoneNumber,
    String? avatarUrl,
    String? avatarBase64,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      final snapshot = await userRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy người dùng',
        };
      }

      final currentData = snapshot.data() as Map<String, dynamic>;
      final normalizedEmail = email.trim().toLowerCase();
      final trimmedName = name.trim();
      final trimmedPhone = phoneNumber?.trim() ?? '';
      final trimmedAvatarUrl = avatarUrl?.trim() ?? '';
      final trimmedAvatarBase64 = avatarBase64?.trim() ?? '';
      final trimmedNewPassword = newPassword?.trim() ?? '';

      if (trimmedName.isEmpty) {
        return {
          'success': false,
          'message': 'Tên không được để trống',
        };
      }

      if (normalizedEmail.isEmpty) {
        return {
          'success': false,
          'message': 'Email không được để trống',
        };
      }

      final currentEmail =
          (currentData['email'] ?? '').toString().toLowerCase();
      if (normalizedEmail != currentEmail) {
        final duplicateQuery = await _db
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .get();

        final hasDuplicate = duplicateQuery.docs.any((doc) => doc.id != userId);
        if (hasDuplicate) {
          return {
            'success': false,
            'message': 'Email đã được sử dụng',
          };
        }
      }

      final updateData = <String, dynamic>{
        'name': trimmedName,
        'email': normalizedEmail,
        'phoneNumber': trimmedPhone,
        'avatarUrl': trimmedAvatarUrl,
        'avatarBase64': trimmedAvatarBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (trimmedNewPassword.isNotEmpty) {
        if ((currentPassword ?? '').trim().isEmpty) {
          return {
            'success': false,
            'message': 'Vui lòng nhập mật khẩu hiện tại',
          };
        }

        final storedPassword = (currentData['password'] ?? '').toString();
        final normalizedCurrentPassword = currentPassword!.trim();
        final hashedCurrentPassword = _hashPassword(normalizedCurrentPassword);
        final isCurrentPasswordValid =
            storedPassword == normalizedCurrentPassword ||
                storedPassword == hashedCurrentPassword;

        if (!isCurrentPasswordValid) {
          return {
            'success': false,
            'message': 'Mật khẩu hiện tại không đúng',
          };
        }

        updateData['password'] = _hashPassword(trimmedNewPassword);
      }

      await userRef.update(updateData);

      final refreshedSnapshot = await userRef.get();
      return {
        'success': true,
        'user': _convertTimestamps({
          'id': refreshedSnapshot.id,
          ...?refreshedSnapshot.data(),
        }),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể cập nhật hồ sơ: $e',
      };
    }
  }

  /// Lấy user theo ID
  static Future<Map<String, dynamic>?> getUserById(String oduserId) async {
    final doc = await _db.collection('users').doc(oduserId).get();
    if (doc.exists) {
      return _convertTimestamps(
          {'id': doc.id, ...doc.data() as Map<String, dynamic>});
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

  /// Rời khỏi house hiện tại
  static Future<void> leaveHouse({
    required String userId,
    required String houseId,
  }) async {
    await _db.collection('users').doc(userId).update({
      'houseId': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('houses').doc(houseId).update({
      'memberCount': FieldValue.increment(-1),
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
    final houseId = house.id;
    
    // Check if user is already a member or has a pending request
    final existingRequest = await _db
        .collection('houses')
        .doc(houseId)
        .collection('joinRequests')
        .where('userId', isEqualTo: userId)
        .get();
    
    if (existingRequest.docs.isNotEmpty) {
      return {
        'success': false,
        'message': 'Bạn đã gửi yêu cầu tham gia phòng này rồi',
      };
    }

    // Create a pending join request
    final userData = await getUserById(userId);
    await _db
        .collection('houses')
        .doc(houseId)
        .collection('joinRequests')
        .add({
      'userId': userId,
      'userName': userData?['name'] ?? 'Người dùng',
      'email': userData?['email'] ?? '',
      'status': 'pending', // pending, approved, rejected
      'requestedAt': DateTime.now(),
      'approvedBy': '',
      'approvedAt': '',
    });

    // Notify house admin
    final owner = await getUserById(houseData['ownerId'] ?? '');
    if (owner != null) {
      await createNotification(
        recipientUserId: houseData['ownerId'] ?? '',
        houseId: houseId,
        title: 'Yêu cầu tham gia phòng',
        message: '${userData?['name'] ?? 'Người dùng'} muốn tham gia phòng ${houseData['name']}',
        type: 'join_request',
        relatedId: houseId,
      );
    }

    return {
      'success': true,
      'message': 'Yêu cầu tham gia đã được gửi. Vui lòng chờ admin duyệt.',
      'isPending': true,
    };
  }

  /// Get pending join requests for a house (for admin)
  static Future<List<Map<String, dynamic>>> getPendingJoinRequests(String houseId) async {
    try {
      final snapshot = await _db
          .collection('houses')
          .doc(houseId)
          .collection('joinRequests')
          .where('status', isEqualTo: 'pending')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()} as Map<String, dynamic>)
          .toList() as List<Map<String, dynamic>>;
    } catch (e) {
      return [];
    }
  }

  /// Approve a join request
  static Future<Map<String, dynamic>> approveJoinRequest({
    required String houseId,
    required String requestId,
    required String userId,
    required String adminId,
  }) async {
    try {
      // Update request status
      await _db
          .collection('houses')
          .doc(houseId)
          .collection('joinRequests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'approvedBy': adminId,
        'approvedAt': DateTime.now(),
      });

      // Add user to house
      await updateUserHouse(userId, houseId);

      // Increment member count
      await _db.collection('houses').doc(houseId).update({
        'memberCount': FieldValue.increment(1),
      });

      // Notify user
      final userData = await getUserById(userId);
      final houseData = await getHouseById(houseId);
      
      if (userData != null) {
        await createNotification(
          recipientUserId: userId,
          houseId: houseId,
          title: 'Yêu cầu được duyệt',
          message: 'Bạn đã được phê duyệt tham gia phòng ${houseData?['name'] ?? 'phòng'}',
          type: 'join_approved',
          relatedId: houseId,
        );
      }

      return {
        'success': true,
        'message': 'Đã duyệt yêu cầu tham gia',
        'houseId': houseId,
      };
    } catch (e) {
      throw Exception('Lỗi duyệt yêu cầu: $e');
    }
  }

  /// Reject a join request
  static Future<Map<String, dynamic>> rejectJoinRequest({
    required String houseId,
    required String requestId,
    required String userId,
    required String adminId,
  }) async {
    try {
      // Update request status
      await _db
          .collection('houses')
          .doc(houseId)
          .collection('joinRequests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'approvedBy': adminId,
        'approvedAt': DateTime.now(),
      });

      // Notify user
      final houseData = await getHouseById(houseId);
      
      await createNotification(
        recipientUserId: userId,
        houseId: houseId,
        title: 'Yêu cầu bị từ chối',
        message: 'Yêu cầu tham gia phòng ${houseData?['name'] ?? 'phòng'} đã bị từ chối',
        type: 'join_rejected',
        relatedId: houseId,
      );

      return {
        'success': true,
        'message': 'Đã từ chối yêu cầu tham gia',
      };
    } catch (e) {
      throw Exception('Lỗi từ chối yêu cầu: $e');
    }
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

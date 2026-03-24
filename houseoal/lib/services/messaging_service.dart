import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class MessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Gửi tin nhắn vào chat room
  static Future<void> sendMessage({
    required String houseId,
    required String senderId,
    required String senderName,
    required String content,
    required String? avatarUrl,
    String? avatarBase64,
    String? imageUrl,
  }) async {
    try {
      await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('messages')
          .add(Message(
            id: '',
            roomId: houseId,
            senderId: senderId,
            senderName: senderName,
            content: content,
            createdAt: DateTime.now(),
            avatarUrl: avatarUrl,
            avatarBase64: avatarBase64,
            imageUrl: imageUrl,
          ).toMap());
    } catch (e) {
      throw Exception('Lỗi gửi tin nhắn: $e');
    }
  }

  /// Lấy danh sách tin nhắn của một phòng
  static Future<List<Message>> getMessages(String houseId) async {
    try {
      final snapshot = await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => Message.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy tin nhắn: $e');
    }
  }

  /// Stream tin nhắn real-time
  static Stream<List<Message>> getMessagesStream(String houseId) {
    return _firestore
        .collection('houses')
        .doc(houseId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Xóa tin nhắn
  static Future<void> deleteMessage(String houseId, String messageId) async {
    try {
      await _firestore
          .collection('houses')
          .doc(houseId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Lỗi xóa tin nhắn: $e');
    }
  }
}

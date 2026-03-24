import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';
import '../models/post.dart';
import 'firestore_service.dart';

class FeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tạo bài post mới
  static Future<void> createPost({
    required String authorId,
    required String authorName,
    required String houseId,
    required String houseName,
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    String? avatarUrl,
    String? avatarBase64,
  }) async {
    try {
      await _firestore.collection('posts').add(Post(
        id: '',
        authorId: authorId,
        authorName: authorName,
        houseId: houseId,
        houseName: houseName,
        title: title,
        content: content,
        imageUrl: imageUrl,
        category: category,
        avatarUrl: avatarUrl,
        avatarBase64: avatarBase64,
        createdAt: DateTime.now(),
      ).toMap());
    } catch (e) {
      throw Exception('Lỗi tạo bài post: $e');
    }
  }

  /// Lấy tất cả bài posts (Global Feed)
  static Future<List<Post>> getGlobalFeed() async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bài posts: $e');
    }
  }

  /// Stream bài posts real-time
  static Stream<List<Post>> getGlobalFeedStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Lấy bài posts của một house
  static Future<List<Post>> getHousePostsFeed(String houseId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('houseId', isEqualTo: houseId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bài posts của phòng: $e');
    }
  }

  /// Lấy bài post theo ID
  static Future<Post?> getPostById(String postId) async {
    try {
      final snapshot = await _firestore.collection('posts').doc(postId).get();
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Post.fromMap(snapshot.id, snapshot.data()!);
    } catch (e) {
      throw Exception('Lỗi lấy bài post: $e');
    }
  }

  /// Lấy luồng comment của bài post
  static Stream<List<Comment>> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Thêm bình luận cho bài post
  static Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
    String? avatarUrl,
    String? avatarBase64,
  }) async {
    try {
      final post = await getPostById(postId);
      if (post == null) throw Exception('Không tìm thấy bài viết');

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(Comment(
            id: '',
            postId: postId,
            userId: userId,
            userName: userName,
            content: content,
            createdAt: DateTime.now(),
            avatarUrl: avatarUrl,
            avatarBase64: avatarBase64,
          ).toMap());

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });

      if (post.authorId.isNotEmpty && post.authorId != userId) {
        await FirestoreService.createNotification(
          recipientUserId: post.authorId,
          houseId: post.houseId,
          title: 'Bình luận mới',
          message: '$userName đã bình luận bài viết của bạn',
          type: 'comment',
          relatedId: postId,
        );
      }
    } catch (e) {
      throw Exception('Lỗi bình luận bài viết: $e');
    }
  }

  /// Like bài post
  static Future<void> likePost(String postId, String userId, String userName) async {
    try {
      final post = await getPostById(postId);
      if (post == null) throw Exception('Không tìm thấy bài viết');

      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
        'likes': FieldValue.increment(1),
      });

      if (post.authorId.isNotEmpty && post.authorId != userId) {
        await FirestoreService.createNotification(
          recipientUserId: post.authorId,
          houseId: post.houseId,
          title: 'Bài viết được thích',
          message: '$userName đã thích bài viết của bạn',
          type: 'like',
          relatedId: postId,
        );
      }
    } catch (e) {
      throw Exception('Lỗi like bài post: $e');
    }
  }

  /// Unlike bài post
  static Future<void> unlikePost(String postId, String userId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi unlike bài post: $e');
    }
  }

  /// Xóa bài post
  static Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      throw Exception('Lỗi xóa bài post: $e');
    }
  }

  /// Xóa bình luận
  static Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Lỗi xóa bình luận: $e');
    }
  }

  /// Thêm trả lời bình luận
  static Future<void> addReplyToComment({
    required String postId,
    required String commentId,
    required String userId,
    required String userName,
    required String content,
    String? avatarUrl,
    String? avatarBase64,
  }) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add({
        'userId': userId,
        'userName': userName,
        'content': content,
        'avatarUrl': avatarUrl,
        'avatarBase64': avatarBase64,
        'createdAt': DateTime.now(),
      });

      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({
        'replyCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Lỗi trả lời bình luận: $e');
    }
  }

  /// Lấy luồng trả lời của bình luận
  static Stream<List<Map<String, dynamic>>> getRepliesStream(String postId, String commentId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Tìm bài posts theo category
  static Future<List<Post>> getPostsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => Post.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy bài posts theo category: $e');
    }
  }
}

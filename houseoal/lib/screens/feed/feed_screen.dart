import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../models/comment.dart';
import '../../services/feed_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/user_avatar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _userId;
  String? _userName;
  String? _userAvatarUrl;
  String? _userAvatarBase64;
  String _selectedCategory = 'all'; // 'all', 'help', 'market', 'news', 'event'

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await AuthService.getFirebaseUserId();
    final userName = await AuthService.getCurrentUserName();

    String? avatarUrl;
    String? avatarBase64;
    if (userId != null && userId.isNotEmpty) {
      final userDoc = await FirestoreService.getUser(userId);
      avatarUrl = (userDoc?['avatarUrl'] ?? '').toString();
      if (avatarUrl.isEmpty) avatarUrl = null;
      avatarBase64 = (userDoc?['avatarBase64'] ?? '').toString();
      if (avatarBase64.isEmpty) avatarBase64 = null;
    }

    setState(() {
      _userId = userId;
      _userName = userName;
      _userAvatarUrl = avatarUrl;
      _userAvatarBase64 = avatarBase64;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Tin Tức'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/create-post'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCategoryChip('all', 'Tất cả'),
                _buildCategoryChip('help', 'Cần giúp'),
                _buildCategoryChip('market', 'Chợ'),
                _buildCategoryChip('event', 'Sự kiện'),
                _buildCategoryChip('roommate', 'Tìm bạn'),
              ],
            ),
          ),

          // Posts List
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: FeedService.getGlobalFeedStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Chưa có bài post nào'));
                }

                var posts = snapshot.data!;
                if (_selectedCategory != 'all') {
                  posts = posts
                      .where((p) => p.category == _selectedCategory)
                      .toList();
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isLiked = post.likedBy.contains(_userId);

                    return Card(
                      margin: const EdgeInsets.all(12),
                      color: _getCategoryColor(post.category).withValues(alpha: 0.1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(post.category).withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                UserAvatar(
                                  name: post.authorName,
                                  avatarUrl: post.avatarUrl,
                                  avatarBase64: post.avatarBase64,
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        post.houseName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    _getCategoryLabel(post.category),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: _getCategoryColor(post.category),
                                  labelStyle: const TextStyle(color: Colors.white),
                                ),
                                if (post.authorId == _userId)
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete, size: 18, color: Colors.red),
                                            const SizedBox(width: 8),
                                            const Text('Xóa bài viết'),
                                          ],
                                        ),
                                        onTap: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Xóa bài viết?'),
                                              content: const Text('Bạn có chắc muốn xóa bài viết này?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            try {
                                              await FeedService.deletePost(post.id);
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Đã xóa bài viết')),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi khi xóa: $e')),
                                                );
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),

                          // Content
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.content,
                                  maxLines: 6,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          if (post.imageUrl != null) ...[
                            const SizedBox(height: 8),
                            Image.network(
                              post.imageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],

                          // See more button
                          if (post.content.length > 200)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: GestureDetector(
                                onTap: () => _showPostDetail(post),
                                child: Text(
                                  'Xem thêm',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Actions
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : null,
                                      ),
                                      onPressed: () async {
                                        if (_userId != null) {
                                          if (isLiked) {
                                            await FeedService.unlikePost(post.id, _userId!);
                                          } else {
                                            await FeedService.likePost(
                                              post.id,
                                              _userId!,
                                              _userName ?? 'Người dùng',
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    Text('${post.likes}'),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(Icons.comment_outlined),
                                      onPressed: () => _showComments(post),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('${post.comments}'),
                                  ],
                                ),
                                Text(
                                  _formatTime(post.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetail(Post post) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    UserAvatar(
                      name: post.authorName,
                      avatarUrl: post.avatarUrl,
                      avatarBase64: post.avatarBase64,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            post.houseName,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Content
                Text(post.content),
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  Image.network(post.imageUrl!, fit: BoxFit.cover),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = value);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'help':
        return Colors.orange;
      case 'market':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      case 'roommate':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'help':
        return 'Cần giúp';
      case 'market':
        return 'Chợ';
      case 'event':
        return 'Sự kiện';
      case 'roommate':
        return 'Tìm bạn';
      default:
        return 'Tin tức';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays}d trước';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showComments(Post post) {
    final controller = TextEditingController();
    String? replyingToCommentId;
    String? replyingToUserName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 6,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Bình luận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder<List<Comment>>(
                        stream: FeedService.getCommentsStream(post.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('Chưa có bình luận nào'));
                          }

                          final comments = snapshot.data!;
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: comments.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final isOwnComment = comment.userId == _userId;
                              final isReplyingToThis = replyingToCommentId == comment.id;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      UserAvatar(
                                        name: comment.userName,
                                        avatarUrl: comment.avatarUrl,
                                        avatarBase64: comment.avatarBase64,
                                        radius: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  comment.userName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                if (isOwnComment)
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text('Xóa bình luận?'),
                                                          content: const Text('Bạn có chắc muốn xóa bình luận này?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, false),
                                                              child: const Text('Hủy'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, true),
                                                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm == true) {
                                                        try {
                                                          await FeedService.deleteComment(post.id, comment.id);
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(content: Text('Đã xóa bình luận')),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(content: Text('Lỗi khi xóa: $e')),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    child: const Icon(Icons.delete, size: 16, color: Colors.red),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(comment.content),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  _formatTime(comment.createdAt),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                                const SizedBox(width: 16),
                                                GestureDetector(
                                                  onTap: () {
                                                    setModalState(() {
                                                      if (replyingToCommentId == comment.id) {
                                                        replyingToCommentId = null;
                                                        replyingToUserName = null;
                                                      } else {
                                                        replyingToCommentId = comment.id;
                                                        replyingToUserName = comment.userName;
                                                      }
                                                    });
                                                  },
                                                  child: Text(
                                                    isReplyingToThis ? 'Hủy' : 'Trả lời',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isReplyingToThis ? Colors.red : Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (replyingToUserName != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trả lời @$replyingToUserName',
                                  style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      replyingToCommentId = null;
                                      replyingToUserName = null;
                                    });
                                  },
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: replyingToUserName != null
                                        ? 'Viết trả lời...'
                                        : 'Viết bình luận...',
                                    border: InputBorder.none,
                                  ),
                                  minLines: 1,
                                  maxLines: 4,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () async {
                                  final text = controller.text.trim();
                                  if (text.isEmpty) return;
                                  if (_userId == null) return;

                                  try {
                                    if (replyingToCommentId != null) {
                                      // Add reply to comment
                                      await FeedService.addReplyToComment(
                                        postId: post.id,
                                        commentId: replyingToCommentId!,
                                        userId: _userId!,
                                        userName: _userName ?? 'Người dùng',
                                        content: text,
                                        avatarUrl: _userAvatarUrl,
                                        avatarBase64: _userAvatarBase64,
                                      );
                                    } else {
                                      // Add regular comment
                                      await FeedService.addComment(
                                        postId: post.id,
                                        userId: _userId!,
                                        userName: _userName ?? 'Người dùng',
                                        content: text,
                                        avatarUrl: _userAvatarUrl,
                                        avatarBase64: _userAvatarBase64,
                                      );
                                    }

                                    controller.clear();
                                    setModalState(() {
                                      replyingToCommentId = null;
                                      replyingToUserName = null;
                                    });
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Lỗi: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

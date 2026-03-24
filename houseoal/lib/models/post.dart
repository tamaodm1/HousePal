class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String houseId;
  final String houseName;
  final String title;
  final String content;
  final String? imageUrl;
  final String category; // 'help', 'market', 'news', 'event', 'roommate'
  final int likes;
  final int comments;
  final List<String> likedBy;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? avatarBase64;

  Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.houseId,
    required this.houseName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    this.likes = 0,
    this.comments = 0,
    this.likedBy = const [],
    required this.createdAt,
    this.avatarUrl,
    this.avatarBase64,
  });

  factory Post.fromMap(String id, Map<String, dynamic> data) {
    return Post(
      id: id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      houseId: data['houseId'] ?? '',
      houseName: data['houseName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'news',
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'],
      avatarBase64: data['avatarBase64'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'houseId': houseId,
      'houseName': houseName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'likes': likes,
      'comments': comments,
      'likedBy': likedBy,
      'createdAt': createdAt,
      'avatarUrl': avatarUrl,
      'avatarBase64': avatarBase64,
    };
  }
}

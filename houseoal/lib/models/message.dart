class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? avatarBase64;
  final String? imageUrl;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.avatarUrl,
    this.avatarBase64,
    this.imageUrl,
  });

  factory Message.fromMap(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      avatarUrl: data['avatarUrl'],
      avatarBase64: data['avatarBase64'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': createdAt,
      'avatarUrl': avatarUrl,
      'avatarBase64': avatarBase64,
      'imageUrl': imageUrl,
    };
  }
}

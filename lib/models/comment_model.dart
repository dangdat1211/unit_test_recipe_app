// comment_model.dart
class CommentModel {
  final String id;
  final String author;
  final String avatarUrl;
  final DateTime createdAt;
  final String content;
  final String userId;

  CommentModel({
    required this.id,
    required this.author,
    required this.avatarUrl,
    required this.createdAt,
    required this.content,
    required this.userId,
  });

  factory CommentModel.fromFirestore(Map<String, dynamic> data, String id) {
    return CommentModel(
      id: id,
      author: data['author'],
      avatarUrl: data['avatarUrl'],
      createdAt: DateTime.parse(data['createdAt']),
      content: data['content'],
      userId: data['userId'],
    );
  }
}

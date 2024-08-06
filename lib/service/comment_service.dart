import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/comment_model.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class CommentService {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final UserService _userService;

  CommentService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    UserService? userService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService(),
       _userService = userService ?? UserService();

  // Thêm bình luận mới
  Future<void> addComment(
      String recipeId, String userId, String content) async {
    if (recipeId =='' || userId == '' || content=='') {
      throw Exception();
    }
    try {
      final recipeSnapshot =
          await _firestore.collection('recipes').doc(recipeId).get();
      final recipeData = recipeSnapshot.data();
      final String otherUserId = recipeData?['userID'] ?? '';

      await _firestore.collection('comments').add({
        'recipeID': recipeId,
        'userId': userId,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // if (userId != otherUserId) {
      //   await _notificationService.createNotification(
      //       content: 'vừa bình luận vào công thức của bạn',
      //       fromUser: userId,
      //       userId: otherUserId,
      //       recipeId: recipeId,
      //       screen: 'comment');
      //   Map<String, dynamic> currentUserInfo =
      //       await _userService.getUserInfo(otherUserId);
      //   await _notificationService.sendNotification(
      //       currentUserInfo['FCM'],
      //       'Bình luận mới mới',
      //       '${currentUserInfo['fullname']} vừa bình luận vào công thức của bạn',
      //       data: {'screen': 'comment', 'recipeId': recipeId, 'userId': otherUserId}
      //       );
      // }
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  // Lấy danh sách bình luận cho một công thức
  Future<List<CommentModel>> getComments(String recipeId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('recipeID', isEqualTo: recipeId)
          .orderBy('createdAt', descending: false)
          .get();

      List<CommentModel> comments = [];
      for (var doc in snapshot.docs) {
        var commentData = doc.data();
        var userId = commentData['userId'];
        var userSnapshot =
            await _firestore.collection('users').doc(userId).get();
        var userData = userSnapshot.data();
        if (userData != null) {
          comments.add(CommentModel.fromFirestore({
            ...commentData,
            'author': userData['fullname'],
            'avatarUrl': userData['avatar'],
          }, doc.id));
        }
      }
      return comments;
    } catch (e) {
      print('Error getting comments: $e');
      throw e;
    }
  }

  // Xóa bình luận
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      print('Error deleting comment: $e');
      throw e;
    }
  }

  // Kiểm tra quyền xóa bình luận
  bool canDeleteComment(
      String currentUserId, String commentUserId, String recipeUserId) {
    return currentUserId == commentUserId || currentUserId == recipeUserId;
  }
}

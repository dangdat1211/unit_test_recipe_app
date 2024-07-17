import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class FollowService {

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final UserService _userService;

  FollowService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
    UserService? userService
  }) 
      : _firestore = firestore ?? FirebaseFirestore.instance,
      _notificationService = notificationService ?? NotificationService(),
      _userService = userService ?? UserService();


  Future<void> toggleFollow(String userId, String otherUserId) async {

    DocumentReference currentUserRef =
        _firestore.collection('users').doc(userId);
    DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
    List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

    DocumentReference otherUser =
      _firestore.collection('users').doc(otherUserId);
    DocumentSnapshot otherUserSnapshot = await otherUser.get();
    List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

    if (followings.contains(otherUserId)) {
      // Nếu đang theo dõi, xóa userId khỏi danh sách
      followings.remove(otherUserId);
      followers.remove(userId);
    } else {
      // Nếu chưa theo dõi, thêm userId vào danh sách
      followings.add(otherUserId);
      followers.add(userId);

      await _notificationService.createNotification(
        content: 'vừa mới theo dõi bạn', 
        fromUser: userId,
        userId: otherUserId,
        recipeId: '',
        screen: 'user'
      );
      Map<String, dynamic> currentUserInfo = await _userService.getUserInfo(otherUserId);
      await _notificationService.sendNotification(currentUserInfo['FCM'], 'Theo dõi mới', '${currentUserInfo['fullname']} vừa theo dõi bạn ',
      data: {'screen': 'user', 'userId': otherUserId});

    }
    await currentUserRef.update({'followings': followings});
    await otherUser.update({'followers': followers});

  }
}
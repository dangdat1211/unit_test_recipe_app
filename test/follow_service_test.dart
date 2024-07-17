import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipe_app/service/follow_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

// Mock các service phụ thuộc
class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<void> createNotification({
    required String content,
    required String fromUser,
    required String userId,
    required String recipeId,
    required String screen,
  }) async {
    // Do nothing in the fake implementation
  }

}
  class MockUserService extends Mock implements UserService {
    @override
  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    return {
      'FCM': 'testFCMToken',
      'fullname': 'Test User',
    };
  }
  }

void main() {
  group('FollowService', () {
    late FollowService followService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockNotificationService mockNotificationService;
    late MockUserService mockUserService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockNotificationService = MockNotificationService();
      mockUserService = MockUserService();

      // Inject fake Firestore vào FollowService
      followService = FollowService (
        firestore: fakeFirestore,
        notificationService: mockNotificationService,
        userService: mockUserService,
        );
    });

    test('toggleFollow should add user to followings and followers when not following', () async {
      // Arrange
      const userId = 'user1';
      const otherUserId = 'user2';
      
      await fakeFirestore.collection('users').doc(userId).set({
        'followings': [],
      });
      await fakeFirestore.collection('users').doc(otherUserId).set({
        'followers': [],
        'FCM': 'testFCMToken',
        'fullname': 'Test User',
      });

      // when(mockUserService.getUserInfo(otherUserId)).thenAnswer((_) async => {
      //   'FCM': 'testFCMToken',
      //   'fullname': 'Test User',
      // });

      // Act
      await followService.toggleFollow(userId, otherUserId);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      final otherUserDoc = await fakeFirestore.collection('users').doc(otherUserId).get();

      print(userDoc.data()!['followings']);

      expect(userDoc.data()!['followings'], contains(otherUserId));
      expect(otherUserDoc.data()!['followers'], contains(userId));

      verify(mockNotificationService.createNotification(
        content: 'vừa mới theo dõi bạn',
        fromUser: userId,
        userId: otherUserId,
        recipeId: '',
        screen: 'user'
      )).called(1);

      verify(mockNotificationService.sendNotification(
        'testFCMToken',
        'Theo dõi mới',
        'Test User vừa theo dõi bạn ',
        data: {'screen': 'user', 'userId': otherUserId}
      )).called(1);
    });

    // test('toggleFollow should remove user from followings and followers when already following', () async {
    //   // Arrange
    //   final userId = 'user1';
    //   final otherUserId = 'user2';
      
    //   await fakeFirestore.collection('users').doc(userId).set({
    //     'followings': [otherUserId],
    //   });
    //   await fakeFirestore.collection('users').doc(otherUserId).set({
    //     'followers': [userId],
    //   });

    //   // Act
    //   await followService.toggleFollow(userId, otherUserId);

    //   // Assert
    //   final userDoc = await fakeFirestore.collection('users').doc(userId).get();
    //   final otherUserDoc = await fakeFirestore.collection('users').doc(otherUserId).get();

    //   expect(userDoc.data()!['followings'], isEmpty);
    //   expect(otherUserDoc.data()!['followers'], isEmpty);

    //   verifyNever(mockNotificationService.createNotification(
    //     content: any(named: 'content'),
    //     fromUser: any(named: 'fromUser'),
    //     userId: any(named: 'userId'),
    //     recipeId: any(named: 'recipeId'),
    //     screen: any(named: 'screen')
    //   ));

    //   verifyNever(mockNotificationService.sendNotification(
    //     any,
    //     any,
    //     any,
    //     data: any(named: 'data')
    //   ));
    // });
  });
}
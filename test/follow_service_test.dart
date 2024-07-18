import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:recipe_app/service/follow_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

// Define mock classes for NotificationService and UserService
class MockNotificationService extends Mock implements NotificationService {}
class MockUserService extends Mock implements UserService {}

void main() {
  group('FollowService Tests', () {
    late FollowService followService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockNotificationService notificationService;
    late MockUserService userService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      notificationService = MockNotificationService();
      userService = MockUserService();
      followService = FollowService(
        firestore: fakeFirestore,
        notificationService: notificationService,
        userService: userService,
      );
    });

    test('toggleFollow - start following', () async {
      // Mock user data
      final userId = 'user123';
      final otherUserId = 'otherUser456';
      await fakeFirestore.collection('users').doc(userId).set({
        'followings': [],
        'FCM': 'mock_fcm_token',
        'fullname': 'Other User',
      });
      await fakeFirestore.collection('users').doc(otherUserId).set({
        'followers': [],
        'FCM': 'mock_fcm_token',
        'fullname': 'Other User',
      });

      // Mock getUserInfo response
      when(userService.getUserInfo(otherUserId)).thenAnswer((_) async => {
        'FCM': 'mock_fcm_token',
        'fullname': 'Other User',
      });

      // Mock createNotification to return Future<void>
      when(notificationService.createNotification(
        content: ('content'),
        fromUser: ('fromUser'),
        userId: ('userId'),
        recipeId: ('recipeId'),
        screen: ('screen'),
      )).thenAnswer((_) async => Future.value());

      // Mock sendNotification to return Future<void>
      when(notificationService.sendNotification(
        'any',
        'any',
        'any',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Future.value());

      // Perform toggleFollow
      await followService.toggleFollow(userId, otherUserId);

      // Assertions
      final currentUserDoc = await fakeFirestore.collection('users').doc(userId).get();
      final otherUserDoc = await fakeFirestore.collection('users').doc(otherUserId).get();

      expect(currentUserDoc.data()?['followings'], contains(otherUserId));
      expect(otherUserDoc.data()?['followers'], contains(userId));

      // Verify notificationService method calls
      verify(notificationService.createNotification(
        content: 'vừa mới theo dõi bạn',
        fromUser: userId,
        userId: otherUserId,
        recipeId: '',
        screen: 'user',
      )).called(1);

      verify(notificationService.sendNotification(
        'mock_fcm_token',
        'Theo dõi mới',
        'Other User vừa theo dõi bạn',
        data: {'screen': 'user', 'userId': otherUserId},
      )).called(1);
    });

    // Add more test cases as needed
  });
}

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/service/notification_service.dart';

void main() {

  group('NotificationService Tests', () {
    late NotificationService notificationService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      notificationService = NotificationService(firestore: fakeFirestore);
    });

    test('create notification successfully', () async {
      // Arrange
      final content = 'New comment on your recipe';
      final fromUser = 'user123';
      final userId = 'user456';
      final recipeId = 'recipe789';
      final screen = 'RecipeDetailScreen';

      // Act
      await notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      );

      // Assert
      final notificationsSnapshot = await fakeFirestore.collection('notifications').get();
      expect(notificationsSnapshot.docs.length, 1);
      final notification = notificationsSnapshot.docs.first;
      expect(notification.data()['content'], content);
      expect(notification.data()['fromUser'], fromUser);
      expect(notification.data()['userId'], userId);
      expect(notification.data()['recipeId'], recipeId);
      expect(notification.data()['screen'], screen);
      expect(notification.data()['isRead'], false);
    });

    test('create notification when new follow successfully', () async {
      // Arrange
      final content = 'Có người mới theo dõi bạn';
      final fromUser = 'user123';
      final userId = 'user456';
      final recipeId = '';
      final screen = 'user';

      // Act
      await notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      );

      // Assert
      final notificationsSnapshot = await fakeFirestore.collection('notifications').get();
      expect(notificationsSnapshot.docs.length, 1);
      final notification = notificationsSnapshot.docs.first;
      expect(notification.data()['content'], content);
      expect(notification.data()['fromUser'], fromUser);
      expect(notification.data()['userId'], userId);
      expect(notification.data()['recipeId'], recipeId);
      expect(notification.data()['screen'], screen);
      expect(notification.data()['isRead'], false);
    });

    test('create notification new recipe successfully', () async {
      // Arrange
      final content = 'Người bạn đang theo dõi vừa đăng 1 công thức mới';
      final fromUser = 'user123';
      final userId = 'user456';
      final recipeId = 'recipe789';
      final screen = 'recipe';

      // Act
      await notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      );

      // Assert
      final notificationsSnapshot = await fakeFirestore.collection('notifications').get();
      expect(notificationsSnapshot.docs.length, 1);
      final notification = notificationsSnapshot.docs.first;
      expect(notification.data()['content'], content);
      expect(notification.data()['fromUser'], fromUser);
      expect(notification.data()['userId'], userId);
      expect(notification.data()['recipeId'], recipeId);
      expect(notification.data()['screen'], screen);
      expect(notification.data()['isRead'], false);
    });

    test('create notification approval recipe successfully', () async {
      // Arrange
      final content = 'Công thức của bạn đã được phê duyệt';
      final fromUser = 'user123';
      final userId = 'user456';
      final recipeId = 'recipe789';
      final screen = 'recipe';

      // Act
      await notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      );

      // Assert
      final notificationsSnapshot = await fakeFirestore.collection('notifications').get();
      expect(notificationsSnapshot.docs.length, 1);
      final notification = notificationsSnapshot.docs.first;
      expect(notification.data()['content'], content);
      expect(notification.data()['fromUser'], fromUser);
      expect(notification.data()['userId'], userId);
      expect(notification.data()['recipeId'], recipeId);
      expect(notification.data()['screen'], screen);
      expect(notification.data()['isRead'], false);
    });

    test('create notification refuse recipe successfully', () async {
      // Arrange
      final content = 'Công thức của bạn đã bì từ chối';
      final fromUser = 'user123';
      final userId = 'user456';
      final recipeId = 'recipe789';
      final screen = 'recipe';
      final reason = 'Lỗi';

      // Act
      await notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      );

      // Assert
      final notificationsSnapshot = await fakeFirestore.collection('notifications').get();
      expect(notificationsSnapshot.docs.length, 1);
      final notification = notificationsSnapshot.docs.first;
      expect(notification.data()['content'], content);
      expect(notification.data()['fromUser'], fromUser);
      expect(notification.data()['userId'], userId);
      expect(notification.data()['recipeId'], recipeId);
      expect(notification.data()['screen'], screen);
      expect(notification.data()['isRead'], false);
    });

    test('throw Exception when fail send Notification', () async {
      final content = 'Công thức của bạn đã bì từ chối';
      final fromUser = '';
      final userId = 'user456';
      final recipeId = 'recipe789';
      final screen = 'recipe';

      expect(() => notificationService.createNotification(
        content: content,
        fromUser: fromUser,
        userId: userId,
        recipeId: recipeId,
        screen: screen,
      ),
          throwsA(isA<Exception>()));
    });

  });
}

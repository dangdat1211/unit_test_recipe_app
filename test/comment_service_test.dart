import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:recipe_app/service/comment_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockUserService extends Mock implements UserService {
  
}

void main() {
  group('CommentService Tests', () {
    late CommentService commentService;
    late FakeFirebaseFirestore fakeFirestore;
    late MockNotificationService mockNotificationService;
    late MockUserService mockUserService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockNotificationService = MockNotificationService();
      mockUserService = MockUserService();
      commentService = CommentService(
        firestore: fakeFirestore,
        notificationService: mockNotificationService,
        userService: mockUserService,
      );
    });

    test('addComment adds a comment successfully', () async {
      // Arrange
      final recipeId = 'recipe1';
      final userId = 'user1';
      final content = 'Great recipe!';
      
      await fakeFirestore.collection('recipes').doc(recipeId).set({
        'userID': 'otherUser',
      });

      when(mockUserService.getUserInfo(userId)).thenAnswer((_) async => {
        'FCM': 'someToken',
        'fullname': 'Test User',
      });

      // Act
      await commentService.addComment(recipeId, userId, content);

      // Assert
      final comments = await fakeFirestore.collection('comments').get();
      expect(comments.docs.length, 1);
      expect(comments.docs.first.data()['content'], content);
      verify(mockNotificationService.createNotification(
        content: 'Content',
        fromUser: userId,
        userId: 'otherUser',
        recipeId: recipeId,
        screen: 'comment',
      )).called(1);
    });

    test('getComments returns correct list of comments', () async {
      // Arrange
      final recipeId = 'recipe1';
      await fakeFirestore.collection('comments').add({
        'recipeID': recipeId,
        'userId': 'user1',
        'content': 'Comment 1',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await fakeFirestore.collection('comments').add({
        'recipeID': recipeId,
        'userId': 'user2',
        'content': 'Comment 2',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await fakeFirestore.collection('users').doc('user1').set({
        'fullname': 'User 1',
        'avatar': 'avatar1.jpg',
      });
      await fakeFirestore.collection('users').doc('user2').set({
        'fullname': 'User 2',
        'avatar': 'avatar2.jpg',
      });

      // Act
      final comments = await commentService.getComments(recipeId);

      // Assert
      expect(comments.length, 2);
      expect(comments[0].content, 'Comment 1');
      expect(comments[1].content, 'Comment 2');
    });

    test('deleteComment deletes a comment successfully', () async {
      // Arrange
      final commentId = 'comment1';
      await fakeFirestore.collection('comments').doc(commentId).set({
        'content': 'Test comment',
      });

      // Act
      await commentService.deleteComment(commentId);

      // Assert
      final commentDoc = await fakeFirestore.collection('comments').doc(commentId).get();
      expect(commentDoc.exists, false);
    });

    test('canDeleteComment returns correct boolean', () {
      // Arrange
      final currentUserId = 'user1';
      final commentUserId = 'user2';
      final recipeUserId = 'user3';

      // Act & Assert
      expect(commentService.canDeleteComment(currentUserId, currentUserId, recipeUserId), true);
      expect(commentService.canDeleteComment(currentUserId, commentUserId, currentUserId), true);
      expect(commentService.canDeleteComment(currentUserId, commentUserId, recipeUserId), false);
    });
  });
}
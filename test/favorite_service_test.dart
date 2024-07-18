// import 'package:flutter/src/widgets/framework.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
// import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
// import 'package:mockito/mockito.dart';
// import 'package:recipe_app/service/favorite_service.dart';
// import 'package:recipe_app/service/notification_service.dart';
// import 'package:recipe_app/service/user_service.dart';

// class MockNotificationService extends Mock implements NotificationService {}
// class MockUserService extends Mock implements UserService {}

// class MockBuildContext extends Mock implements BuildContext {}

// void main() {
//   group('FavoriteService Tests', () {
//     late FavoriteService favoriteService;
//     late FakeFirebaseFirestore fakeFirestore;
//     late MockFirebaseAuth mockAuth;
//     late MockNotificationService mockNotificationService;
//     late MockUserService mockUserService;
//     late MockBuildContext mockContext;

//     setUp(() {
//       fakeFirestore = FakeFirebaseFirestore();
//       final user = MockUser(uid: 'testUser');
//       mockAuth = MockFirebaseAuth(mockUser: user);
//       mockNotificationService = MockNotificationService();
//       mockUserService = MockUserService();
//       mockContext = MockBuildContext();
//       favoriteService = FavoriteService(
//         firestore: fakeFirestore,
//         auth: mockAuth,
//         notificationService: mockNotificationService,
//         userService: mockUserService,
//       );
//     });

//     test('isRecipeFavorite returns true when recipe is favorited', () async {
//       await fakeFirestore.collection('favorites').add({
//         'userId': 'testUser',
//         'recipeId': 'recipe1',
//       });

//       final result = await favoriteService.isRecipeFavorite('recipe1', 'testUser' );

//       expect(result, true);
//     });

//     test('isRecipeFavorite returns false when recipe is not favorited', () async {
//       final result = await favoriteService.isRecipeFavorite('recipe1', 'testUser');

//       expect(result, false);
//     });

//     test('toggleFavorite adds recipe to favorites when not favorited', () async {
//       await fakeFirestore.collection('recipes').doc('recipe1').set({
//         'likes': [],
//       });
//       when(mockUserService.getUserInfo('testUser')).thenAnswer((_) async => {
//         'FCM': 'someToken',
//         'fullname': 'Test User',
//       });

//       await favoriteService.toggleFavorite(mockContext, 'recipe1', 'otherUser', 'testUser');

//       final favorites = await fakeFirestore.collection('favorites').get();
//       expect(favorites.docs.length, 1);
//       expect(favorites.docs.first.data()['recipeId'], 'recipe1');
      
//       final recipe = await fakeFirestore.collection('recipes').doc('recipe1').get();
//       expect(recipe.data()?['likes'], ['testUser']);
      
//       verify(mockNotificationService.createNotification(
//         content: 'Content',
//         fromUser: 'testUser',
//         userId: 'otherUser',
//         recipeId: 'recipe1',
//         screen: 'recipe',
//       )).called(1);
//     });

//     test('toggleFavorite removes recipe from favorites when already favorited', () async {
//       await fakeFirestore.collection('favorites').add({
//         'userId': 'testUser',
//         'recipeId': 'recipe1',
//       });
//       await fakeFirestore.collection('recipes').doc('recipe1').set({
//         'likes': ['testUser'],
//       });

//       await favoriteService.toggleFavorite(mockContext, 'recipe1', 'testUser', 'testUser');

//       final favorites = await fakeFirestore.collection('favorites').get();
//       expect(favorites.docs.length, 0);
      
//       final recipe = await fakeFirestore.collection('recipes').doc('recipe1').get();
//       expect(recipe.data()?['likes'], []);
//     });
//   });
// }
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipe_app/service/rate_service.dart';

void main() {
  group('RateService Tests', () {
    late RateService rateService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      rateService = RateService(firestore: fakeFirestore);
    });

    test('getAverageRating returns correct average', () async {
      // Arrange
      final recipeId = 'recipe1';
      await fakeFirestore.collection('rates').add({
        'recipeId': recipeId,
        'star': 4.0,
      });
      await fakeFirestore.collection('rates').add({
        'recipeId': recipeId,
        'star': 5.0,
      });

      // Act
      final avgRating = await rateService.getAverageRating(recipeId);

      // Assert
      expect(avgRating, 4.5);
    });

    test('getAverageRating returns 0.0 for no ratings', () async {
      // Act
      final avgRating = await rateService.getAverageRating('nonexistentRecipe');

      // Assert
      expect(avgRating, 0.0);
    });

    test('fetchAverageRating returns correct data', () async {
      // Arrange
      final recipeId = 'recipe1';
      final userId = 'user1';
      await fakeFirestore.collection('rates').add({
        'recipeId': recipeId,
        'userId': userId,
        'star': 4.0,
      });
      await fakeFirestore.collection('rates').add({
        'recipeId': recipeId,
        'userId': 'user2',
        'star': 5.0,
      });

      // Act
      final result = await rateService.fetchAverageRating(recipeId, userId);

      // Assert
      expect(result['avgRating'], 4.5);
      expect(result['ratingCount'], 2);
      expect(result['hasRated'], true);
    });

    test('getUserRating returns correct rating', () async {
      // Arrange
      final userId = 'user1';
      final recipeId = 'recipe1';
      await fakeFirestore.collection('rates').doc('${userId}_$recipeId').set({
        'userId': userId,
        'recipeId': recipeId,
        'star': 4.0,
      });

      // Act
      final userRating = await rateService.getUserRating(userId, recipeId);

      // Assert
      expect(userRating, 4.0);
    });

    test('getUserRating returns 0.0 for no rating', () async {
      // Act
      final userRating = await rateService.getUserRating('nonexistentUser', 'nonexistentRecipe');

      // Assert
      expect(userRating, 0.0);
    });

    test('updateRating creates new rating', () async {
      // Arrange
      final userId = 'user1';
      final recipeId = 'recipe1';
      final rating = 4.5;

      // Act
      await rateService.updateRating(userId, recipeId, rating);

      // Assert
      final docSnapshot = await fakeFirestore.collection('rates').doc('${userId}_$recipeId').get();
      expect(docSnapshot.exists, true);
      expect(docSnapshot.get('star'), rating);
    });

    test('updateRating updates existing rating', () async {
      // Arrange
      final userId = 'user1';
      final recipeId = 'recipe1';
      final initialRating = 3.0;
      final updatedRating = 4.5;

      await fakeFirestore.collection('rates').doc('${userId}_$recipeId').set({
        'userId': userId,
        'recipeId': recipeId,
        'star': initialRating,
      });

      // Act
      await rateService.updateRating(userId, recipeId, updatedRating);

      // Assert
      final docSnapshot = await fakeFirestore.collection('rates').doc('${userId}_$recipeId').get();
      expect(docSnapshot.exists, true);
      expect(docSnapshot.get('star'), updatedRating);
    });
  });
}
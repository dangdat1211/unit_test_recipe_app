import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/service/recipe_service.dart';

void main() {
  group('RecipeService Tests', () {
    late RecipeService recipeService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      recipeService = RecipeService(firestore: fakeFirestore);
    });

    test('upload recipe and steps successfully ', () async {
      // Arrange
      final mainImageUrl = 'https://example.com/image.jpg';
      final stepImageUrls = [['https://example.com/step1.jpg'], ['https://example.com/step2.jpg']];
      
      final recipe = RecipeModel(
        namerecipe: 'Test Recipe',
        description: 'Test Description',
        ingredients: ['Ingredient 1', 'Ingredient 2'],
        steps: ['Step 1', 'Step 2'],
        userID: 'testUser',
        level: 'Khó',
        ration: '4 nguoi',
        time: '10',
        image: mainImageUrl,
        urlYoutube: ''
      );

      // Create a user document before uploading the recipe
      await fakeFirestore.collection('users').doc('testUser').set({
        'recipes': [],
        'updateAt': DateTime.now(),
      });

      // Act
      await recipeService.uploadRecipe(recipe, mainImageUrl, stepImageUrls);

      // Assert
      final recipeDoc = await fakeFirestore.collection('recipes').get();
      expect(recipeDoc.docs.length, 1);
      expect(recipeDoc.docs.first.data()['namerecipe'], 'Test Recipe');

      final stepsDoc = await fakeFirestore.collection('steps').get();
      expect(stepsDoc.docs.length, 2);

      // Check if the user document was updated
      final userDoc = await fakeFirestore.collection('users').doc('testUser').get();
      expect(userDoc.exists, true);
      expect((userDoc.data()?['recipes'] as List).length, 1);
    });

    test('get recipe not found', () async {
      // Act & Assert
      expect(() => recipeService.getRecipe('nonexistentId'), 
             throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Recipe not found'))));
    });

    test('getRecipeSteps should return correct steps', () async {
      // Arrange
      final recipeId = 'testRecipeId';
      await fakeFirestore.collection('steps').add({
        'title': 'Step 1',
        'images': ['https://example.com/step1.jpg'],
        'recipeID': recipeId,
        'order': 1,
      });
      await fakeFirestore.collection('steps').add({
        'title': 'Step 2',
        'images': ['https://example.com/step2.jpg'],
        'recipeID': recipeId,
        'order': 2,
      });

      // Act
      final steps = await recipeService.getRecipeSteps(recipeId);

      // Assert
      expect(steps.length, 2);
      expect(steps[0]['title'], 'Step 1');
      expect(steps[1]['title'], 'Step 2');
      expect(steps[0]['order'], 1);
      expect(steps[1]['order'], 2);
    });

    test('getRecipeSteps should return empty list for non-existent recipe', () async {
      // Act
      final steps = await recipeService.getRecipeSteps('nonexistentId');

      // Assert
      expect(steps, isEmpty);
    });

    test('uploadRecipe should update user document', () async {
      // Arrange
      final userId = 'testUser';
      final recipe = RecipeModel(
        namerecipe: 'Test Recipe',
        description: 'Test Description',
        ingredients: ['Ingredient 1'],
        steps: ['Step 1'],
        userID: userId,
        level: 'Easy',
        ration: '2 servings',
        time: '30 minutes',
        image: 'https://example.com/image.jpg',
        urlYoutube: ''
      );

      await fakeFirestore.collection('users').doc(userId).set({
        'recipes': [],
        'updateAt': DateTime.now(),
      });

      // Act
      await recipeService.uploadRecipe(recipe, 'https://example.com/image.jpg', [['https://example.com/step1.jpg']]);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(userId).get();
      expect(userDoc.exists, true);
      expect((userDoc.data()?['recipes'] as List).length, 1);
    });

    test('uploadRecipe should create steps documents', () async {
      // Arrange
      final recipe = RecipeModel(
        namerecipe: 'Test Recipe',
        description: 'Test Description',
        ingredients: ['Ingredient 1', 'Ingredient 2'],
        steps: ['Step 1', 'Step 2'],
        userID: 'testUser',
        level: 'Medium',
        ration: '4 servings',
        time: '45 minutes',
        image: 'https://example.com/image.jpg',
        urlYoutube: ''
      );

      await fakeFirestore.collection('users').doc('testUser').set({
        'recipes': [],
        'updateAt': DateTime.now(),
      });

      // Act
      await recipeService.uploadRecipe(
        recipe, 
        'https://example.com/image.jpg', 
        [['https://example.com/step1.jpg'], ['https://example.com/step2.jpg']]
      );

      // Assert
      final stepsSnapshot = await fakeFirestore.collection('steps').get();
      expect(stepsSnapshot.docs.length, 2);
      expect(stepsSnapshot.docs[0].data()['title'], 'Step 1');
      expect(stepsSnapshot.docs[1].data()['title'], 'Step 2');
      expect(stepsSnapshot.docs[0].data()['images'], ['https://example.com/step1.jpg']);
      expect(stepsSnapshot.docs[1].data()['images'], ['https://example.com/step2.jpg']);
    });

    test('approveRecipe - success', () async {
      // Arrange
      final recipeId = 'recipe123';
      await fakeFirestore.collection('recipes').doc(recipeId).set({
        'status': 'Đợi phê duyệt',
      });

      // Act
      await recipeService.approveRecipe(recipeId);

      // Assert
      final updatedDoc = await fakeFirestore.collection('recipes').doc(recipeId).get();
      expect(updatedDoc.get('status'), 'Đã được phê duyệt');
    });

    test('rejectRecipe - success', () async {
      // Arrange
      final recipeId = 'recipe123';
      await fakeFirestore.collection('recipes').doc(recipeId).set({
        'status': 'Đợi phê duyệt',
      });

      // Act
      await recipeService.rejectRecipe(recipeId, 'Bị từ chối');

      // Assert
      final updatedDoc = await fakeFirestore.collection('recipes').doc(recipeId).get();
      expect(updatedDoc.get('status'), 'Bị từ chối');
      expect(updatedDoc.get('rejectionReason'), 'NBị từ chối');
    });

    test('deleteRecipe - success', () async {
      // Arrange
      final recipeId = 'recipe123';
      await fakeFirestore.collection('recipes').doc(recipeId).set({
        'name': 'Test Recipe',
      });
      await fakeFirestore.collection('rates').add({
        'recipeId': recipeId,
        'rate': 5,
      });
      await fakeFirestore.collection('comments').add({
        'recipeId': recipeId,
        'comment': 'Great recipe!',
      });

      // Act
      await recipeService.deleteRecipe(recipeId);

      // Assert
      final recipeDoc = await fakeFirestore.collection('recipes').doc(recipeId).get();
      expect(recipeDoc.exists, false);

      final ratesQuery = await fakeFirestore.collection('rates').where('recipeId', isEqualTo: recipeId).get();
      expect(ratesQuery.docs.isEmpty, true);

      final commentsQuery = await fakeFirestore.collection('comments').where('recipeId', isEqualTo: recipeId).get();
      expect(commentsQuery.docs.isEmpty, true);
    });

    test('hideRecipe - success', () async {
      // Arrange
      final recipeId = 'recipe123';
      await fakeFirestore.collection('recipes').doc(recipeId).set({
        'isHidden': false,
      });

      // Act
      await recipeService.hideRecipe(recipeId);

      // Assert
      final updatedDoc = await fakeFirestore.collection('recipes').doc(recipeId).get();
      expect(updatedDoc.get('isHidden'), true);
    });

    test('approveRecipe - failure (recipe not found)', () async {
      expect(() => recipeService.approveRecipe('nonexistent_recipe'),
          throwsA(isA<Exception>()));
    });

    test('rejectRecipe - failure (recipe not found)', () async {
      expect(() => recipeService.rejectRecipe('nonexistent_recipe', 'Not suitable'),
          throwsA(isA<Exception>()));
    });

    test('deleteRecipe - failure (recipe not found)', () async {
      expect(() => recipeService.deleteRecipe('nonexistent_recipe'),
          throwsA(isA<Exception>()));
    });

    test('hideRecipe - failure (recipe not found)', () async {
      expect(() => recipeService.hideRecipe('nonexistent_recipe'),
          throwsA(isA<Exception>()));
    });

  });

  
}
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipe_app/service/admin_service/ingredient_service.dart';

void main() {
  group('IngredientService', () {
    late IngredientService ingredientService;
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      ingredientService = IngredientService(firestore: fakeFirestore);
    });

    test('addIngredient should add ingredient to Firestore', () async {
      await ingredientService.addIngredient('Salt', 'salt', 'url_to_salt_image');

      // Get all documents in the collection 'ingredients'
      final ingredientsSnapshot = await fakeFirestore.collection('ingredients').get();

      // Check if there is at least one document
      expect(ingredientsSnapshot.docs.isNotEmpty, true);

      // Get the first document in the collection
      final addedIngredient = ingredientsSnapshot.docs.first;

      // Assert the data of the added ingredient
      expect(addedIngredient.data(), {
        'name': 'Salt',
        'keysearch': 'salt',
        'image': 'url_to_salt_image',
        'createAt': anyOf(isA<String>(), equals(DateTime.now().toIso8601String())),
      });
    });

    test('deleteIngredient should delete ingredient from Firestore', () async {
      var docRef = await fakeFirestore.collection('ingredients').add({
        'name': 'Sugar',
        'keysearch': 'sugar',
        'image': 'url_to_sugar_image',
      });

      await ingredientService.deleteIngredient(docRef.id);

      var deletedIngredient = await fakeFirestore.collection('ingredients').doc(docRef.id).get();

      expect(deletedIngredient.exists, false);
    });

    test('updateIngredient should update ingredient in Firestore', () async {
      var docRef = await fakeFirestore.collection('ingredients').add({
        'name': 'Flour',
        'keysearch': 'flour',
        'image': 'url_to_flour_image',
      });

      await ingredientService.updateIngredient(docRef.id, 'Modified Flour', 'modified', 'url_to_modified_image');

      var updatedIngredient = await fakeFirestore.collection('ingredients').doc(docRef.id).get();

      expect(updatedIngredient.data(), {
        'name': 'Modified Flour',
        'keysearch': 'modified',
        'image': 'url_to_modified_image',
        'createAt': anyOf(isA<String>(), equals(DateTime.now().toIso8601String())),
      });
    });

    test('fetchAndSearchIngredients should return filtered ingredients', () async {
      await fakeFirestore.collection('ingredients').add({
        'name': 'Salt',
        'keysearch': 'salt',
        'image': 'url_to_salt_image',
      });

      await fakeFirestore.collection('ingredients').add({
        'name': 'Sugar',
        'keysearch': 'sugar',
        'image': 'url_to_sugar_image',
      });

      var ingredients = await ingredientService.fetchAndSearchIngredients(
        sortBy: 'name',
        sortAscending: true,
        searchQuery: 'salt',
      ).first;

      expect(ingredients.length, 1);
      expect(ingredients.first['name'], 'Salt');
    });
  });
}

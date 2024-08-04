// recipe_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore;

  RecipeService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> uploadRecipe(RecipeModel recipe, String? mainImageUrl, List<List<String>> stepImageUrls) async {
    try {
      // Add the recipe document and get its ID
      DocumentReference recipeDoc = await _firestore.collection('recipes').add(recipe.toMap());
      String recipeId = recipeDoc.id;

      // Collection reference for steps
      CollectionReference stepsCollection = _firestore.collection('steps');

      // List to store step IDs
      List<String> stepIds = [];

      for (int i = 0; i < recipe.steps.length; i++) {
        final stepText = recipe.steps[i];
        final stepImages = stepImageUrls[i];

        // Create a step document with recipeID and order
        DocumentReference stepDoc = await stepsCollection.add({
          'title': stepText,
          'images': stepImages,
          'recipeID': recipeId,
          'order': i + 1,
        });

        stepIds.add(stepDoc.id);
      }

      await recipeDoc.update({
        'steps': stepIds,
        'image': mainImageUrl ?? '',
      });

      // Update user's recipes
      DocumentReference userDoc = _firestore.collection('users').doc(recipe.userID);
      await userDoc.update({
        'recipes': FieldValue.arrayUnion([recipeId]),
        'updateAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error uploading recipe: $e');
      throw e;
    }
  }

  Future<RecipeModel> getRecipe(String recipeId) async {
    DocumentSnapshot recipeSnapshot = await _firestore.collection('recipes').doc(recipeId).get();
    if (recipeSnapshot.exists) {
      return RecipeModel.fromMap(recipeSnapshot.data() as Map<String, dynamic>, recipeId);
    } else {
      throw Exception('Recipe not found');
    }
  }

  Future<List<Map<String, dynamic>>> getRecipeSteps(String recipeId) async {
    QuerySnapshot stepsSnapshot = await _firestore.collection('steps')
        .where('recipeID', isEqualTo: recipeId)
        .orderBy('order')
        .get();
    
    return stepsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> approveRecipe(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'status': 'Đã được phê duyệt',
      });
    } catch (e) {
      print('Error approving recipe: $e');
      throw Exception('Failed to approve recipe: $e');
    }
  }

  Future<void> rejectRecipe(String recipeId, String reason) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'status': 'Bị từ chối',
        'rejectionReason': reason,
      });
    } catch (e) {
      print('Error rejecting recipe: $e');
      throw Exception('Failed to reject recipe: $e');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
  try {
    // Kiểm tra xem recipe có tồn tại không
    final recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();
    if (!recipeDoc.exists) {
      throw Exception('Recipe not found');
    }

    WriteBatch batch = _firestore.batch();

    // Delete recipe
    batch.delete(_firestore.collection('recipes').doc(recipeId));

    // Delete related data
    await _deleteRelatedData(batch, recipeId, 'rates');
    await _deleteRelatedData(batch, recipeId, 'comments');
    await _deleteRelatedData(batch, recipeId, 'favorites');
    await _deleteRelatedData(batch, recipeId, 'steps');

    await batch.commit();
  } catch (e) {
    if (e is Exception) {
      throw e;
    }
    throw Exception('Failed to delete recipe: $e');
  }
}

  Future<void> _deleteRelatedData(WriteBatch batch, String recipeId, String collectionName) async {
    QuerySnapshot relatedDocs = await _firestore.collection(collectionName)
        .where('recipeId', isEqualTo: recipeId)
        .get();
    for (var doc in relatedDocs.docs) {
      batch.delete(doc.reference);
    }
  }

  Future<void> hideRecipe(String recipeId) async {
    try {
      await _firestore.collection('recipes').doc(recipeId).update({
        'isHidden': true,
      });
    } catch (e) {
      print('Error hiding recipe: $e');
      throw Exception('Failed to hide recipe: $e');
    }
  }
}
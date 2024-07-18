import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class IngredientService {
  final FirebaseFirestore _firestore ;

  IngredientService({
    FirebaseFirestore? firestore
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addIngredient(String name, String keysearch, String imageUrl) async {
    if (name.isEmpty || keysearch.isEmpty || imageUrl.isEmpty) {
      throw ArgumentError('All fields must be provided and cannot be empty.');
    }
    await _firestore.collection('ingredients').add({
      'name': name,
      'keysearch': keysearch,
      'image': imageUrl,
      'createAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteIngredient(String ingredientId) async {
    if (ingredientId.isEmpty) {
      throw ArgumentError('Ingredient ID must be provided and cannot be empty.');
    }
    await _firestore.collection('ingredients').doc(ingredientId).delete();
  }

  Stream<QuerySnapshot> fetchIngredients({required String sortBy, required bool sortAscending}) {
    if (sortBy.isEmpty) {
      throw ArgumentError('SortBy field must be provided and cannot be empty.');
    }
    return _firestore
        .collection('ingredients')
        .orderBy(sortBy, descending: !sortAscending)
        .snapshots();
  }

  Future<void> updateIngredient(String id, String name, String keysearch, String imageUrl) async {
    if (id.isEmpty || name.isEmpty || keysearch.isEmpty || imageUrl.isEmpty) {
      throw ArgumentError('All fields must be provided and cannot be empty.');
    }
    await _firestore.collection('ingredients').doc(id).update({
      'name': name,
      'keysearch': keysearch,
      'image': imageUrl,
      'createAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> fetchAndSearchIngredients({required String sortBy, required bool sortAscending, required String searchQuery}) {
    return _firestore
        .collection('ingredients')
        .orderBy(sortBy, descending: !sortAscending)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
              .where((ingredient) =>
                  ingredient['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
                  ingredient['keysearch'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        });
  }
}

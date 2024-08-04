import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final FirebaseFirestore _firestore;

  CategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addCategory({
    required String? name,
    required String? description,
    required String? image,
  }) async {
    if (name == null || name.isEmpty) {
      throw ArgumentError('Name cannot be null or empty');
    }
    if (description == null) {
      throw ArgumentError('Description cannot be null');
    }
    if (image == null) {
      throw ArgumentError('Image cannot be null');
    }

    await _firestore.collection('categories').add({
      'name': name,
      'description': description,
      'image': image,
      'createAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String? categoryId,
    required String? name,
    required String? description,
    String? image,
  }) async {
    if (categoryId == null || categoryId.isEmpty) {
      throw ArgumentError('Category ID cannot be null or empty');
    }
    if (name == null || name.isEmpty) {
      throw ArgumentError('Name cannot be null or empty');
    }
    if (description == null) {
      throw ArgumentError('Description cannot be null');
    }

    final updateData = {
      'name': name,
      'description': description,
      'updateAt': FieldValue.serverTimestamp(),
    };
    if (image != null) {
      updateData['image'] = image;
    }

    await _firestore.collection('categories').doc(categoryId).update(updateData);
  }

  Future<void> deleteCategory(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) {
      throw ArgumentError('Category ID cannot be null or empty');
    }
    await _firestore.collection('categories').doc(categoryId).delete();
  }

  Stream<QuerySnapshot> getCategoriesStream({
    required String sortBy,
    required bool sortAscending,
  }) {
    return _firestore
        .collection('categories')
        .orderBy(sortBy, descending: !sortAscending)
        .snapshots();
  }

  Future<DocumentSnapshot> getCategoryById(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      throw ArgumentError('Category ID cannot be null or empty');
    }
    return _firestore.collection('categories').doc(categoryId).get();
  }

  List<Map<String, dynamic>> searchCategories(
    List<QueryDocumentSnapshot> docs,
    String? query,
  ) {
    if (query == null || query.isEmpty) {
      return docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    }
    return docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
        .where((category) =>
            category['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            category['description'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
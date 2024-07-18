// cooking_method_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CookingMethodService {
  final FirebaseFirestore _firestore ;

  CookingMethodService({
    FirebaseFirestore? firestore
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addMethod({
    required String? name,
    required String? keySearch,
    String? imageUrl,
  }) async {
    if (name == null || name.isEmpty) {
      throw Exception('Tên phương pháp không được để trống');
    }
    if (keySearch == null || keySearch.isEmpty) {
      throw Exception('Từ khóa tìm kiếm không được để trống');
    }

    Map<String, dynamic> data = {
      'name': name,
      'keysearch': keySearch,
      'createAt': FieldValue.serverTimestamp(),
    };
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['image'] = imageUrl;
    }

    await _firestore.collection('cookingmethods').add(data);
  }

  Future<void> updateMethod({
    required String? id,
    String? name,
    String? keySearch,
    String? imageUrl,
  }) async {
    if (id == null || id.isEmpty) {
      throw Exception('ID phương pháp không được để trống');
    }

    Map<String, dynamic> data = {
      'updateAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      if (name.isEmpty) {
        throw Exception('Tên phương pháp không được để trống');
      }
      data['name'] = name;
    }
    if (keySearch != null) {
      if (keySearch.isEmpty) {
        throw Exception('Từ khóa tìm kiếm không được để trống');
      }
      data['keysearch'] = keySearch;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['image'] = imageUrl;
    }

    await _firestore.collection('cookingmethods').doc(id).update(data);
  }

  Future<void> deleteMethod(String? id) async {
    if (id == null || id.isEmpty) {
      throw Exception('ID phương pháp không được để trống');
    }
    await _firestore.collection('cookingmethods').doc(id).delete();
  }

  Stream<QuerySnapshot> getMethodsStream() {
    return _firestore.collection('cookingmethods').snapshots();
  }

  Future<DocumentSnapshot> getMethodById(String? id) {
    if (id == null || id.isEmpty) {
      throw Exception('ID phương pháp không được để trống');
    }
    return _firestore.collection('cookingmethods').doc(id).get();
  }

  Query<Map<String, dynamic>> searchMethods(String? query) {
    if (query == null || query.isEmpty) {
      throw Exception('Từ khóa tìm kiếm không được để trống');
    }
    return _firestore
        .collection('cookingmethods')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z');
  }
}
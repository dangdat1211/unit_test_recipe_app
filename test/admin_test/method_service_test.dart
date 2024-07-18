import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/service/admin_service/method_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late CookingMethodService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = CookingMethodService(firestore: fakeFirestore);
  });

  group('CookingMethodService', () {
    test('addMethod should add a new method', () async {
      await service.addMethod(
        name: 'Test Method',
        keySearch: 'test',
        imageUrl: 'http://example.com/image.jpg',
      );

      final snapshot = await fakeFirestore.collection('cookingmethods').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'Test Method');
      expect(snapshot.docs.first.data()['keysearch'], 'test');
      expect(snapshot.docs.first.data()['image'], 'http://example.com/image.jpg');
    });

    test('addMethod should throw exception when name is null', () async {
      expect(() => service.addMethod(name: null, keySearch: 'test'),
          throwsException);
    });

    test('updateMethod should update an existing method', () async {
      final docRef = await fakeFirestore.collection('cookingmethods').add({
        'name': 'Old Name',
        'keysearch': 'old',
        'image': 'http://example.com/old.jpg',
      });

      await service.updateMethod(
        id: docRef.id,
        name: 'New Name',
        keySearch: 'new',
        imageUrl: 'http://example.com/new.jpg',
      );

      final updatedDoc = await docRef.get();
      final data = updatedDoc.data() as Map<String, dynamic>;
      expect(data['name'], 'New Name');
      expect(data['keysearch'], 'new');
      expect(data['image'], 'http://example.com/new.jpg');
    });

    test('deleteMethod should delete an existing method', () async {
      final docRef = await fakeFirestore.collection('cookingmethods').add({
        'name': 'To Delete',
        'keysearch': 'delete',
      });

      await service.deleteMethod(docRef.id);

      final snapshot = await fakeFirestore.collection('cookingmethods').get();
      expect(snapshot.docs.length, 0);
    });

    test('getMethodById should return the correct method', () async {
      final docRef = await fakeFirestore.collection('cookingmethods').add({
        'name': 'Test Method',
        'keysearch': 'test',
      });

      final method = await service.getMethodById(docRef.id);
      expect(method.exists, true);
      final data = method.data() as Map<String, dynamic>;
      expect(data['name'], 'Test Method');
    });

    test('searchMethods should return correct results', () async {
      await fakeFirestore.collection('cookingmethods').add({
        'name': 'Apple Pie',
        'keysearch': 'apple',
      });
      await fakeFirestore.collection('cookingmethods').add({
        'name': 'Banana Bread',
        'keysearch': 'banana',
      });

      final query = service.searchMethods('Apple');
      final snapshot = await query.get();
      
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['name'], 'Apple Pie');
    });
  });
}
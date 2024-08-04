import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:recipe_app/service/admin_service/category_service.dart';


void main() {
  late CategoryService categoryService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    categoryService = CategoryService(firestore: fakeFirestore);
  });

  group('CategoryService Tests', () {
    group('addCategory', () {
      test('should add a category when all fields are valid', () async {
        await categoryService.addCategory(
          name: 'Test Category',
          description: 'Test Description',
          image: 'test_image_url',
        );

        final snapshot = await fakeFirestore.collection('categories').get();
        expect(snapshot.docs.length, 1);
        expect(snapshot.docs.first.data()['name'], 'Test Category');
        expect(snapshot.docs.first.data()['description'], 'Test Description');
        expect(snapshot.docs.first.data()['image'], 'test_image_url');
      });

      test('should throw ArgumentError when name is null', () {
        expect(
          () => categoryService.addCategory(
            name: null,
            description: 'Test Description',
            image: 'test_image_url',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when name is empty', () {
        expect(
          () => categoryService.addCategory(
            name: '',
            description: 'Test Description',
            image: 'test_image_url',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when description is null', () {
        expect(
          () => categoryService.addCategory(
            name: 'Test Category',
            description: null,
            image: 'test_image_url',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when image is null', () {
        expect(
          () => categoryService.addCategory(
            name: 'Test Category',
            description: 'Test Description',
            image: null,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updateCategory', () {
      test('should update a category when all fields are valid', () async {
        final docRef = await fakeFirestore.collection('categories').add({
          'name': 'Old Name',
          'description': 'Old Description',
          'image': 'old_image_url',
        });

        await categoryService.updateCategory(
          categoryId: docRef.id,
          name: 'New Name',
          description: 'New Description',
          image: 'new_image_url',
        );

        final updatedDoc = await docRef.get();
        expect(updatedDoc.data()!['name'], 'New Name');
        expect(updatedDoc.data()!['description'], 'New Description');
        expect(updatedDoc.data()!['image'], 'new_image_url');
      });

      test('should throw ArgumentError when categoryId is null', () {
        expect(
          () => categoryService.updateCategory(
            categoryId: null,
            name: 'New Name',
            description: 'New Description',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when name is null', () {
        expect(
          () => categoryService.updateCategory(
            categoryId: 'some_id',
            name: null,
            description: 'New Description',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when description is null', () {
        expect(
          () => categoryService.updateCategory(
            categoryId: 'some_id',
            name: 'New Name',
            description: null,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('deleteCategory', () {
      test('should delete a category when categoryId is valid', () async {
        final docRef = await fakeFirestore.collection('categories').add({
          'name': 'To Be Deleted',
          'description': 'This will be deleted',
        });

        await categoryService.deleteCategory(docRef.id);

        final snapshot = await fakeFirestore.collection('categories').get();
        expect(snapshot.docs.length, 0);
      });

      test('should throw ArgumentError when categoryId is null', () {
        expect(
          () => categoryService.deleteCategory(null),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when categoryId is empty', () {
        expect(
          () => categoryService.deleteCategory(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('getCategoriesStream', () {
      test('should return a stream of categories', () async {
        await fakeFirestore.collection('categories').add({
          'name': 'Category 1',
          'description': 'Description 1',
        });
        await fakeFirestore.collection('categories').add({
          'name': 'Category 2',
          'description': 'Description 2',
        });

        final stream = categoryService.getCategoriesStream(sortBy: 'name', sortAscending: true);
        final snapshot = await stream.first;
        expect(snapshot.docs.length, 2);
      });
    });

    group('getCategoryById', () {
      test('should return a category when categoryId is valid', () async {
        final docRef = await fakeFirestore.collection('categories').add({
          'name': 'Test Category',
          'description': 'Test Description',
        });

        final category = await categoryService.getCategoryById(docRef.id);
        expect(category.exists, true);
        // expect(category.data()?['name'], 'Test Category');
      });

      test('should throw ArgumentError when categoryId is null', () {
        expect(
          () => categoryService.getCategoryById(null),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when categoryId is empty', () {
        expect(
          () => categoryService.getCategoryById(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('searchCategories', () {
      test('should return matching categories when query is valid', () async {
        await fakeFirestore.collection('categories').add({
          'name': 'Fruits',
          'description': 'All kinds of fruits',
        });
        await fakeFirestore.collection('categories').add({
          'name': 'Vegetables',
          'description': 'Fresh vegetables',
        });

        final snapshot = await fakeFirestore.collection('categories').get();
        final results = categoryService.searchCategories(snapshot.docs, 'fruit');
        expect(results.length, 1);
        expect(results.first['name'], 'Fruits');
      });

      test('should return all categories when query is null', () async {
        await fakeFirestore.collection('categories').add({
          'name': 'Fruits',
          'description': 'All kinds of fruits',
        });
        await fakeFirestore.collection('categories').add({
          'name': 'Vegetables',
          'description': 'Fresh vegetables',
        });

        final snapshot = await fakeFirestore.collection('categories').get();
        final results = categoryService.searchCategories(snapshot.docs, null);
        expect(results.length, 2);
      });

      test('should return all categories when query is empty', () async {
        await fakeFirestore.collection('categories').add({
          'name': 'Fruits',
          'description': 'All kinds of fruits',
        });
        await fakeFirestore.collection('categories').add({
          'name': 'Vegetables',
          'description': 'Fresh vegetables',
        });

        final snapshot = await fakeFirestore.collection('categories').get();
        final results = categoryService.searchCategories(snapshot.docs, '');
        expect(results.length, 2);
      });
    });
  });
}
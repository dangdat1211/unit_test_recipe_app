import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mockito/mockito.dart';
import 'package:recipe_app/service/user_service.dart';

class MockUserCredential extends Mock implements UserCredential {}

class CustomMockUser extends Mock implements User {
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async {
    if ((credential as EmailAuthCredential).password == 'oldPassword') {
      return MockUserCredential();
    } else {
      throw FirebaseAuthException(code: 'wrong-password');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    // Simulate password update
    return;
  }
}

void main() {
  late UserService userService;
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore fakeFirestore;
  late MockUser mockUser;

  setUp(() {
    // mockUser = CustomMockUser() as MockUser;
    // mockUser = MockUser(
    //   uid: 'testUserId',
    //   email: 'test@example.com',
    //   isEmailVerified: true,
    // );
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'testUserId',
        email: 'test@example.com',
        isEmailVerified: true,
      ),
    );
    fakeFirestore = FakeFirebaseFirestore();
    userService = UserService(auth: mockAuth, firestore: fakeFirestore);
  });

  group('changePassword', () {
    test('should change password successfully', () async {
      await expectLater(
        userService.changePassword(
          currentPassword: 'oldPassword',
          newPassword: 'newPassword',
          confirmPassword: 'newPassword',
        ),
        completes,
      );
    });

    test('should throw exception when current password is null', () async {
      expect(
        () => userService.changePassword(
          currentPassword: '',
          newPassword: 'newPassword',
          confirmPassword: 'newPassword',
        ),
        throwsA(isA<Exception>())
      );
    });
    test('should throw exception when new password is same as current password', () {
      expect(
        () => userService.changePassword(
          currentPassword: 'password',
          newPassword: 'password',
          confirmPassword: 'password',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('New password must be different from current password'),
        )),
      );
    });

    test('should throw exception when confirm password does not match', () {
      expect(
        () => userService.changePassword(
          currentPassword: 'oldPassword',
          newPassword: 'newPassword',
          confirmPassword: 'differentPassword',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('New password and confirm password do not match'),
        )),
      );
    });
  });

  group('saveProfileData', () {
    setUp(() async {
      // Thêm một người dùng có sẵn với username 'existinguser'
      await fakeFirestore.collection('users').doc('testUserId').set({
        'username': 'existinguser',
        'fullname': 'Existing User',
        'bio': 'Existing bio',
      });

      await fakeFirestore.collection('users').doc('existinguser').set({
        'username': 'existinguser',
        'fullname': 'Existing User',
        'bio': 'Existing bio',
      });
    });

    test('should update profile data successfully', () async {
      await userService.saveProfileData(
        fullname: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        imageUrl: 'https://example.com/image.jpg',
      );

      var userDoc = await fakeFirestore.collection('users').doc('testUserId').get();
      expect(userDoc.data(), {
        'fullname': 'Test User',
        'username': 'testuser',
        'bio': 'Test bio',
        'avatar': 'https://example.com/image.jpg',
      });
    });

    test('should throw exception when username already exists', () async {
      expect(
        () => userService.saveProfileData(
          fullname: 'Test User',
          username: 'existinguser',
          bio: 'Test bio',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Username already exists'),
        )),
      );
    });
  });

  group('toggleAccountStatus', () {
    test('should toggle account status successfully', () async {
      await fakeFirestore.collection('users').doc('testUserId').set({
        'status': false,
      });

      await userService.toggleAccountStatus('testUserId', true);

      var userDoc = await fakeFirestore.collection('users').doc('testUserId').get();
      expect(userDoc.data()?['status'], true);
    });

    test('should throw exception when user does not exist', () async {
      expect(
        () => userService.toggleAccountStatus('nonExistentUserId', true),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to update account status'),
        )),
      );
    });
  });

  group('changeUserRole', () {
    test('should change user role successfully', () async {
      await fakeFirestore.collection('users').doc('testUserId').set({
        'role': 'Thành viên',
      });

      await userService.changeUserRole('testUserId', 'Chuyên gia');

      var userDoc = await fakeFirestore.collection('users').doc('testUserId').get();
      expect(userDoc.data()?['role'], 'Chuyên gia');
    });

    test('should throw exception when role is invalid', () async {
      expect(
        () => userService.changeUserRole('testUserId', 'InvalidRole'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid role'),
        )),
      );
    });

    test('should throw exception when user does not exist', () async {
      expect(
        () => userService.changeUserRole('nonExistentUserId', 'Chuyên gia'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to change user role'),
        )),
      );
    });
  });
  group('searchUsers', () {
    setUp(() async {
      // Thêm một số người dùng giả vào Firestore
      await fakeFirestore.collection('users').add({
        'fullname': 'John Doe',
        'email': 'john@example.com',
      });
      await fakeFirestore.collection('users').add({
        'fullname': 'Jane Doe',
        'email': 'jane@example.com',
      });
      await fakeFirestore.collection('users').add({
        'fullname': 'Alice Smith',
        'email': 'alice@example.com',
      });
    });

    test('should return matching users when data exists', () async {
      final results = await userService.searchUsers('doe');

      expect(results.length, 2);
      expect(results[0]['fullname'], 'John Doe');
      expect(results[1]['fullname'], 'Jane Doe');
    });

    test('should return empty list when no matching data', () async {
      final results = await userService.searchUsers('xyz');

      expect(results.length, 0);
    });
  });
}
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

    test('should throw exception when current password is incorrect', () async {
      expect(
        () => userService.changePassword(
          currentPassword: 'wrongPassword',
          newPassword: 'newPassword',
          confirmPassword: 'newPassword',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Current password is incorrect'),
        )),
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
}
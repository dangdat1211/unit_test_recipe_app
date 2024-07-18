import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:recipe_app/models/user_model.dart';
import 'package:recipe_app/service/auth_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:mockito/mockito.dart';

class MockNotificationService extends Mock implements NotificationService {
  String? deviceToken;

  @override
  Future<String?> getDeviceToken() async {
    return deviceToken;
  }

  @override
  void requestNotificationPermission() {}

  @override
  void isTokenRefresh() {}
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  Map<String, MockUser> users = {};

  void addUser(MockUser user) {
    users[user.email!] = user;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (email == 'existing@example.com') {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    return MockUserCredential(MockUser(uid: 'newUserId', email: email));
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (users.containsKey(email)) {
      return MockUserCredential(users[email]!);
    }
    throw FirebaseAuthException(code: 'user-not-found');
  }

  @override
  Future<void> signOut() async {
    // Thực hiện logic đăng xuất mặc định nếu cần
    return Future.value();
  }
}

class MockUserCredential extends Mock implements UserCredential {
  final MockUser _mockUser;
  MockUserCredential(this._mockUser);

  @override
  User? get user => _mockUser;
}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      mockNotificationService = MockNotificationService();
      authService = AuthService(
        auth: mockAuth,
        firestore: fakeFirestore,
        notificationService: mockNotificationService,
      );
    });

    group('registerUser', () {
      test('should register user successfully', () async {
        final result = await authService.registerUser(
          username: 'testuser',
          fullname: 'Test User',
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result, isA<UserModel>());
        expect(result.username, 'testuser');
        expect(result.email, 'test@example.com');

        final userDoc =
            await fakeFirestore.collection('users').doc(result.id).get();
        expect(userDoc.exists, true);
        expect(userDoc.data()!['username'], 'testuser');
      });

      test('should throw exception when required field is missing', () async {
        await expectLater(
          authService.registerUser(
            username: '',
            fullname: 'Test User',
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'invalid-input')),
        );
      });

      test('should throw exception when user already exists', () async {
        await expectLater(
          authService.registerUser(
            username: 'newuser',
            fullname: 'New User',
            email: 'existing@example.com',
            password: 'newpassword',
          ),
          throwsA(isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'email-already-in-use')),
        );
      });
    });

    group('signInWithEmailAndPassword', () {
      test('should sign in user successfully', () async {
        // Tạo một user mẫu trong MockFirebaseAuth
        final mockUser = MockUser(
          uid: 'testUid',
          email: 'test@example.com',
          isEmailVerified: true,
        );
        mockAuth.addUser(mockUser);

        // Thiết lập dữ liệu user trong Firestore
        await fakeFirestore.collection('users').doc('testUid').set({
          'username': 'testuser',
          'fullname': 'Test User',
          'email': 'test@example.com',
          'status': true,
          'FCM': 'testFCMToken'
        });

        // when(mockNotificationService.getDeviceToken()).thenAnswer((_) async => 'testFCMToken');

        // Thực hiện đăng nhập
        final result = await authService.signInWithEmailAndPassword(
            'test@example.com', 'password123');

        expect(result, isA<User>());
        expect(result?.email, 'test@example.com');

        final userDoc =
            await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['FCM'], 'testFCMToken');
      });

      test('should throw exception when sign in fails', () async {
        await expectLater(
          authService.signInWithEmailAndPassword(
              'nonexistent@example.com', 'wrongpassword'),
          throwsA(isA<FirebaseAuthException>()
              .having((e) => e.code, 'code', 'user-not-found')),
        );
      });
    });

    group('signOut', () {
      test('should sign out user successfully', () async {
        // Mô phỏng đăng nhập
        final mockUser = MockUser(
          uid: 'testUid',
          email: 'test@example.com',
          isEmailVerified: true,
        );
        mockAuth.addUser(mockUser);

        // Thiết lập dữ liệu user trong Firestore
        await fakeFirestore.collection('users').doc('testUid').set({
          'username': 'testuser',
          'fullname': 'Test User',
          'email': 'test@example.com',
          'status': true,
          'FCM': 'old'
        });

        // Mô phỏng người dùng hiện tại
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Thực hiện đăng xuất
        await authService.signOut();;

        // Xác minh FCM token đã được xóa trong Firestore
        final userDoc =
            await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['FCM'], '');
      });
    });

    group('disableAccount', () {
      test('should disable user account successfully', () async {
        await fakeFirestore.collection('users').doc('testUid').set({
          'status': true,
        });

        await authService.disableAccount('testUid');

        final userDoc =
            await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['status'], false);
      });
    });
  });
}

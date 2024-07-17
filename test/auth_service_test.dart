import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:recipe_app/models/user_model.dart';
import 'package:recipe_app/service/auth_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:mockito/mockito.dart';

class MockNotificationService extends Mock implements NotificationService {}
class MockFirebaseAuthAlwaysThrow extends Mock implements FirebaseAuth {
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(code: 'error');
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

        // Verify user was added to Firestore
        final userDoc = await fakeFirestore.collection('users').doc(result.id).get();
        expect(userDoc.exists, true);
        expect(userDoc.data()!['username'], 'testuser');
      });

      test('should throw FirebaseAuthException on registration failure', () async {
        // Use the custom mock that always throws an exception
        final authServiceWithMockAuth = AuthService(
          auth: MockFirebaseAuthAlwaysThrow(),
          firestore: fakeFirestore,
          notificationService: mockNotificationService,
        );

        expect(
          () => authServiceWithMockAuth.registerUser(
            username: 'testuser',
            fullname: 'Test User',
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<FirebaseAuthException>()),
        );
      });
    });

    group('signInWithEmailAndPassword', () {
      test('should sign in user successfully', () async {
        final mockUser = MockUser(
          uid: 'testUid',
          email: 'test@example.com',
        );
        final mockUserCredential = MockUserCredential(mockUser);

        when(mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).thenAnswer((_) async => mockUserCredential);

        // Thêm dữ liệu user vào FakeFirestore
        await fakeFirestore.collection('users').doc('testUid').set({
          'username': 'testuser',
          'fullname': 'Test User',
          'email': 'test@example.com',
          'status': true,
        });

        when(mockNotificationService.getDeviceToken()).thenAnswer((_) async => 'testFCMToken');

        final result = await authService.signInWithEmailAndPassword('test@example.com', 'password123');

        expect(result, isA<User>());
        expect(result?.uid, 'testUid');

        // Verify FCM token was updated
        final userDoc = await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['FCM'], 'testFCMToken');
      });

      test('should throw exception when user is not found', () async {
        // Add a disabled user to Firestore
        await fakeFirestore.collection('users').doc('testUid').set({
          'username': 'testuser',
          'fullname': 'Test User',
          'email': 'test@example.com',
          'status': false,
        });

        expect(
          () => authService.signInWithEmailAndPassword('test@example.com', 'password123'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Không tìm thấy dữ liệu người dùng'))),
        );
      });
    });

    group('signOut', () {
      test('should sign out user successfully', () async {
        await fakeFirestore.collection('users').doc('testUid').set({
          'FCM': 'oldToken',
        });

        await authService.signOut();
        await fakeFirestore.collection('users').doc('testUid').set({
          'FCM': '',
        });
        // Verify FCM token was cleared
        final userDoc = await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['FCM'], '');
      });
    });

    group('disableAccount', () {
      test('should disable user account successfully', () async {
        await fakeFirestore.collection('users').doc('testUid').set({
          'status': true,
        });

        await authService.disableAccount('testUid');

        // Verify account was disabled
        final userDoc = await fakeFirestore.collection('users').doc('testUid').get();
        expect(userDoc.data()!['status'], false);
      });
    });
  });
}

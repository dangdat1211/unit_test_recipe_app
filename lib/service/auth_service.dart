import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/models/user_model.dart';
import 'package:recipe_app/service/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? NotificationService();

  Future<UserModel> registerUser({
    required String username,
    required String fullname,
    required String email,
    required String password,
  }) async {

    if (username.isEmpty || fullname.isEmpty || email.isEmpty || password.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-input',
        message: 'Tất cả các trường đều phải được điền đầy đủ.',
      );
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      UserModel newUser = UserModel(
        id: userCredential.user!.uid,
        username: username,
        fullname: fullname,
        email: email,
        createAt: DateTime.now(),
        role: 'Thành viên'
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
        throw FirebaseAuthException(code: e.code);
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          bool isActive = userDoc.get('status') ?? true;

          if (!isActive) {
            await _auth.signOut();
            throw FirebaseAuthException(
              code: 'user-disabled',
              message: 'Tài khoản này đã bị vô hiệu hóa.',
            );
          }

          if (!user.emailVerified) {
            throw FirebaseAuthException(
              code: 'email-not-verified',
              message: 'Vui lòng xác minh email của bạn trước khi đăng nhập.',
            );
          }

          String? FCMToken = await _notificationService.getDeviceToken();

          if (FCMToken != null) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .update({'FCM': FCMToken});
          }
        } else {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Không tìm thấy dữ liệu người dùng.',
          );
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print(e);
      throw Exception('Đã xảy ra lỗi không xác định.' );
    }
  }

  Future<void> signOut() async {
    try {
      String? userId = _auth.currentUser?.uid;

      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({'FCM': ''});
      }

      await _auth.signOut();
    } catch (e) {
      throw Exception('Lỗi khi đăng xuất: $e');
    }
  }

  Future<void> removeFCMToken() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({'FCM': ''});
      }
    } catch (e) {
      throw Exception('Lỗi khi xóa token FCM: $e');
    }
  }

  Future<void> disableAccount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': false,
        'updateAt': DateTime.now().toString(),
      });
      print("User account disabled");
    } catch (e) {
      print("Failed to disable account: $e");
      throw e;
    }
  }
  
}
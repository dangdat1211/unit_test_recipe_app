import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveProfileData({
    required String fullname,
    required String username,
    required String bio,
    String? imageUrl,
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    // Check if username already exists
    QuerySnapshot usernameQuery = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
        .get();
    
    if (usernameQuery.docs.isNotEmpty) {
      throw Exception('Username already exists');
    }

    Map<String, dynamic> updateData = {
      'fullname': fullname,
      'username': username,
      'bio': bio,
    };

    if (imageUrl != null) {
      updateData['avatar'] = imageUrl;
    }

    await _firestore.collection('users').doc(currentUser.uid).update(updateData);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    if (newPassword != confirmPassword) {
      throw Exception('New password and confirm password do not match');
    }

    if (currentPassword == newPassword) {
      throw Exception('New password must be different from current password');
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      }
      throw FirebaseAuthException(code: e.code);
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  Future<void> toggleAccountStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': isActive,
      });
    } catch (e) {
      throw Exception('Failed to update account status: $e');
    }
  }

  Future<void> changeUserRole(String userId, String newRole) async {
    if (!['Thành viên', 'Chuyên gia', 'Quản trị viên'].contains(newRole)) {
      throw Exception('Invalid role');
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      throw Exception('Failed to change user role: $e');
    }
  }
}
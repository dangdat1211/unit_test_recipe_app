import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code);
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
}
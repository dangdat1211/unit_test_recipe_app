
import 'package:cloud_firestore/cloud_firestore.dart';



class NotificationService {

  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseFirestore? firestore
  }) : 
      _firestore = firestore ?? FirebaseFirestore.instance;


  Future<void> createNotification({
    required String content,
    required String fromUser,
    required String userId,
    required String recipeId,
    required String screen,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'content': content,
        'createAt': FieldValue.serverTimestamp(),
        'fromUser': fromUser,
        'isRead': false,
        'recipeId': recipeId,
        'screen': screen,
        'userId': userId,
      });
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
      throw e;
    }
  }
}

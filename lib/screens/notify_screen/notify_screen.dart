import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/comment_screen/comment_screen.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';
import 'package:recipe_app/screens/screens.dart'; // Đảm bảo import này có SignInScreen

class NotifyScreen extends StatefulWidget {
  const NotifyScreen({Key? key}) : super(key: key);

  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot>? _notificationsStream;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _notificationsStream = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createAt', descending: true)
          .snapshots();
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {});
  }

  Future<void> _markAllAsRead() async {
    if (currentUser != null) {
      WriteBatch batch = _firestore.batch();
      QuerySnapshot notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      setState(() {});
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('Thông báo'),
        actions: currentUser != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: _markAllAsRead,
                  child: Center(
                    child: Text(
                      'Đánh dấu tất cả là đã đọc',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ]
          : null,
      ),
      body: currentUser == null
          ? _buildNotLoggedInView()
          : _buildNotificationsView(),
    );
  }

  Widget _buildNotLoggedInView() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 150,
            child: Image.asset('assets/logo_noback.png'),
          ),
          Text(
            'Tham gia ngay cùng cộng đồng lớn',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: Text(
              'Đăng nhập ngay',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(child: Text('Không có thông báo nào'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final Timestamp createAt = notification['createAt'] as Timestamp;
              return FutureBuilder<Map<String, dynamic>>(
                future: _getUserInfo(notification['fromUser']),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text('Đang tải...'));
                  }

                  if (userSnapshot.hasError || !userSnapshot.hasData) {
                    return ListTile(
                        title: Text('Không thể tải thông tin người dùng'));
                  }

                  final userData = userSnapshot.data!;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(userData['avatar'] ?? ''),
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text: '${userData['fullname'] ?? 'Người dùng'} ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: notification['content'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text(_getTimeAgo(createAt)),
                      trailing: !notification['isRead']
                          ? Icon(Icons.circle, color: Colors.blue, size: 10)
                          : null,
                      onTap: () {
                        _handleNotificationTap(
                            notification, notifications[index].id);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      Map<String, dynamic> notification, String notificationId) async {
    // Đánh dấu thông báo đã đọc
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});

    // Chuyển hướng dựa trên loại thông báo
    switch (notification['screen']) {
      case 'recipe':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => DetailReCipe(
            recipeId: notification['recipeId'],
            userId: notification['fromUser'],
          ),
        ));
        break;

      case 'comment':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => CommentScreen(
            recipeId: notification['recipeId'],
            userId: notification['userId'],
          ),
        ));
        break;
      case 'user':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileUser(
            userId: notification['fromUser'],
          ),
        ));
        break;
      default:
        // Xử lý mặc định hoặc hiển thị thông báo chi tiết
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết thông báo'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(notification['content'] ?? ''),
            SizedBox(height: 8),
            Text('Thời gian: ${_getTimeAgo(notification['createAt'])}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';
import 'package:recipe_app/service/follow_service.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final int initialTab;

  const FollowersFollowingScreen(
      {super.key, required this.userId, this.initialTab = 0});

  @override
  _FollowersFollowingScreenState createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> followings = [];
  List<String> followers = [];
  Map<String, bool> followingUsers = {};

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _fetchFollowersAndFollowings();
  }

  Future<void> _fetchFollowersAndFollowings() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      followings = List<String>.from(userDoc['followings'] ?? []);
      followers = List<String>.from(userDoc['followers'] ?? []);
    });
    _initFollowingUsers();
  }

  void _initFollowingUsers() async {
    if (currentUser != null) {
      String currentUserId = currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      List<dynamic> currentUserFollowings = userDoc.get('followings') ?? [];
      setState(() {
        followingUsers = {
          for (String userId in [...followings, ...followers])
            userId: currentUserFollowings.contains(userId),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;
          String fullname = userData['fullname'] ?? '';

          return Scaffold(
            appBar: AppBar(
              title: Text(fullname),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Đang theo dõi'),
                  Tab(text: 'Người theo dõi'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowingsList(),
                _buildFollowersList(),
              ],
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Loading...'),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  Widget _buildFollowingsList() {
    return ListView.builder(
      itemCount: followings.length,
      itemBuilder: (context, index) {
        String userId = followings[index];
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Map<String, dynamic> userData =
                  snapshot.data!.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      userData['avatar'] ?? 'https://via.placeholder.com/150'),
                ),
                title: Text(userData['fullname']),
                subtitle: Text(userData['email']),
                trailing: userId == currentUser!.uid ? null :
                ElevatedButton(
                  onPressed: () async {
                    bool isFollowing = followingUsers[userId] ?? false;
                    await FollowService()
                        .toggleFollow(currentUser!.uid, userId);
                    setState(() {
                      followingUsers[userId] = !isFollowing;
                    });
                  },
                  child: Text(
                    followingUsers[userId] == true ? 'Bỏ theo dõi' : 'Theo dõi',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: followingUsers[userId] == true
                        ? Colors.red
                        : Colors.blue,
                  ),
                ), 
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileUser(userId: userId),
                    ),
                  );
                },
              );
            } else {
              return ListTile(
                title: Text('Loading...'),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildFollowersList() {
    return ListView.builder(
      itemCount: followers.length,
      itemBuilder: (context, index) {
        String userId = followers[index];
        return FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Map<String, dynamic> userData =
                  snapshot.data!.data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      userData['avatar'] ?? 'https://via.placeholder.com/150'),
                ),
                title: Text(userData['fullname']),
                subtitle: Text(userData['email']),
                trailing: userId == currentUser!.uid ? null :
                ElevatedButton(
                  onPressed: () async {
                    bool isFollowing = followingUsers[userId] ?? false;
                    await FollowService()
                        .toggleFollow(currentUser!.uid, userId);
                    setState(() {
                      followingUsers[userId] = !isFollowing;
                    });
                  },
                  child: Text(
                    followingUsers[userId] == true ? 'Bỏ theo dõi' : 'Theo dõi',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: followingUsers[userId] == true
                        ? Colors.red
                        : Colors.blue,
                  ),
                ),
              );
            } else {
              return ListTile(
                title: Text('Loading...'),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

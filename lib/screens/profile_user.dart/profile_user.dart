import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/screens/profile_user.dart/infomation_follow_screen.dart';
import 'package:recipe_app/screens/profile_user.dart/my_favorite.dart';
import 'package:recipe_app/screens/profile_user.dart/my_recipe.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/follow_service.dart';

class ProfileUser extends StatefulWidget {
  final String userId;

  const ProfileUser({super.key, required this.userId});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userProfile;

  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkFollow().then((value) {
      setState(() {
        isFollowing = value;
      });
    });
  }

  Future<void> fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    setState(() {
      userProfile = userDoc;
    });
  }

  Future<bool> checkFollow() async {
    if (currentUser != null) {
      String currentUserId = currentUser!.uid;
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      List<dynamic> followedUsers = docSnapshot['followings'] ?? [];
      print(followedUsers);
      return List<String>.from(followedUsers).contains(widget.userId);
    }
    return false;
  }

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('recipes');

  Future<List<Map<String, dynamic>>> _getData() async {
    QuerySnapshot querySnapshot =
        await _collectionRef.where('userID', isEqualTo: widget.userId).get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> _refreshPage() async {
    await fetchUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(userProfile!['fullname'] ?? ''),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPage,
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.network(
                            userProfile!['avatar'].isNotEmpty
                                ? userProfile!['avatar']
                                : 'https://firebasestorage.googleapis.com/v0/b/recipe-app-5a80e.appspot.com/o/profile_images%2F1719150232272?alt=media&token=ea875488-b4bd-43f1-b858-d6eba92e982a', // Đường dẫn tới hình ảnh của bạn trong thư mục assets
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '@' + userProfile!['username'] + ' ',
                              style: TextStyle(),
                            ),
                            if (userProfile!['role'] =='Chuyên gia') 
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: mainColor,
                              ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FollowersFollowingScreen(
                                      userId: widget.userId,
                                      initialTab: 1,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Text((userProfile!['followers'] as List)
                                      .length
                                      .toString()),
                                  Text('Người theo dõi')
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FollowersFollowingScreen(
                                      userId: widget.userId,
                                      initialTab: 0,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Text((userProfile!['followings'] as List)
                                      .length
                                      .toString()),
                                  Text('Đang theo dõi')
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                Text((userProfile!['recipes'] as List)
                                    .length
                                    .toString()),
                                Text('Số công thức')
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (currentUser?.uid == widget.userId)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfile()),
                              ).then((_) {
                                _refreshPage();
                              });
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Sửa hồ sơ',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        if (currentUser?.uid != widget.userId)
                          GestureDetector(
                            onTap: () async {
                              if (currentUser != null) {
                                await FollowService().toggleFollow(
                                    currentUser!.uid, widget.userId);
                                setState(() {
                                  isFollowing = !isFollowing;
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Bạn chưa đăng nhập'),
                                      content: Text(
                                          'Vui lòng đăng nhập để tiếp tục.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const SignInScreen()),
                                            );
                                          },
                                          child: Text('Đăng nhập'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('Hủy'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  isFollowing
                                      ? 'Đang theo dõi'
                                      : 'Theo dõi ngay',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 10),
                        Text(userProfile!['bio']),
                        SizedBox(height: 10),
                        TabBar(
                          dividerColor: Colors.transparent,
                          tabs: [
                            Tab(text: 'Công thức của bạn'),
                            Tab(text: 'Yêu thích'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                MyRecipe(userId: widget.userId),
                MyFavorite(userId: widget.userId)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

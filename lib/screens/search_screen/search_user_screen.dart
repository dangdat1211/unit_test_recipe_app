import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';
import 'package:recipe_app/service/follow_service.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  Map<String, bool> followingUsers = {};

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _initFollowingUsers();
  }

  void _initFollowingUsers() async {
    if (currentUser != null) {
      String currentUserId = currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      List<dynamic> followings = userDoc.get('followings') ?? [];
      setState(() {
        followingUsers = {
          for (String userId in followings) userId: true,
        };
      });
    }
    print(followingUsers);
  }

  void _onSearchSubmitted(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        isLoading = true;
        searchResults.clear();
        followingUsers.clear();
      });

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in snapshot.docs) {
        var userData = userDoc.data() as Map<String, dynamic>;

        if (userData['fullname']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase())) {
          userData['id'] = userDoc.id; // Lấy id từ documentId
          searchResults.add(userData);
          _initFollowingUsers();
        }
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResults.clear();
      followingUsers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm người dùng...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
          ),
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _onSearchSubmitted(_searchController.text);
            },
          ),
        ],
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : searchResults.isNotEmpty
              ? ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final user = searchResults[index];
                    final userId = user['id'];
                    print(userId);
                    print(followingUsers[userId]);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            'https://firebasestorage.googleapis.com/v0/b/recipe-app-5a80e.appspot.com/o/profile_images%2F1718255525561?alt=media&token=1b5d667b-8b74-47f7-af4a-228949f5988b'),
                      ),
                      title: Text(user['fullname']),
                      subtitle: Text(user['email']),
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
                          followingUsers[userId] == true
                              ? 'Hủy theo dõi'
                              : 'Theo dõi',
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
                              builder: (context) => ProfileUser(
                                    userId: userId,
                                  )),
                        );
                      },
                    );
                  },
                )
              : Center(
                  child: Text('Không có kết quả tìm kiếm'),
                ),
    );
  }
}

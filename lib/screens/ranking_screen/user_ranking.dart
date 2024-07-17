import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';
import 'package:recipe_app/service/follow_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class UserRanking extends StatefulWidget {
  const UserRanking({Key? key}) : super(key: key);

  @override
  State<UserRanking> createState() => _UserRankingState();
}

class _UserRankingState extends State<UserRanking> {
  String dropdownValue = 'Người theo dõi';
  List<DocumentSnapshot> users = [];
  String? currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    fetchUsers();

    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        users = snapshot.docs;
        sortUsers();
        _isLoading = false;
      });
    });
  }

  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users')
        .where('status', isEqualTo: true)
        .get();
    setState(() {
      users = snapshot.docs;
      sortUsers();
      _isLoading = false;
    });
  }

  void sortUsers() {
    if (dropdownValue == 'Người theo dõi') {
      users.sort((a, b) {
        final aFollowers = (a.data() as Map<String, dynamic>?)?['followers'];
        final bFollowers = (b.data() as Map<String, dynamic>?)?['followers'];
        final aCount = aFollowers is List ? aFollowers.length : 0;
        final bCount = bFollowers is List ? bFollowers.length : 0;
        return bCount.compareTo(aCount);
      });
    } else {
      users.sort((a, b) {
        final aRecipes = (a.data() as Map<String, dynamic>?)?['recipes'];
        final bRecipes = (b.data() as Map<String, dynamic>?)?['recipes'];
        final aCount = aRecipes is List ? aRecipes.length : 0;
        final bCount = bRecipes is List ? bRecipes.length : 0;
        return bCount.compareTo(aCount);
      });
    }
    users = users.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainColor))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildDropdown(),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      Map<String, dynamic> userData =
                          users[index].data() as Map<String, dynamic>;
                      return _buildUserCard(userData, index);
                    },
                    childCount: users.length,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: mainColor, size: 20),
          style: TextStyle(color: mainColor, fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
              sortUsers();
            });
          },
          items: <String>['Người theo dõi', 'Công thức']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, int index) {
    String userId = users[index].id;
    bool isFollowing = currentUserId != null &&
        (userData['followers'] as List?)?.contains(currentUserId) == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileUser(userId: userId),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.fromLTRB(16, 4, 16, 4),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: EdgeInsets.fromLTRB(16, 16, 8, 16),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(userData['avatar'] ?? ''),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getRankColor(index),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            userData['fullname'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                '@${userData['username'] ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                '${(userData['followers'] as List?)?.length ?? 0} người theo dõi',
                maxLines: 1,
                style: TextStyle(color: mainColor),
              ),
            ],
          ),
          trailing: currentUserId == userId ? null : 
          SizedBox(
            width: 100,
            height: 32,
            child: ElevatedButton(
              onPressed: () {
                FollowService().toggleFollow(currentUserId!, userId);
              },
              child: Text(
                isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                style: TextStyle(
                  color: isFollowing ? Colors.grey[600] : Colors.white,
                  fontSize: 12,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing ? Colors.grey[200] : mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey[400]!;
    if (index == 2) return Colors.brown[300]!;
    return mainColor;
  }
}
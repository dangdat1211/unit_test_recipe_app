import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:recipe_app/widgets/simple_item_recipe.dart';
import 'package:recipe_app/widgets/ui_button.dart';

class AddInfoRecipe extends StatefulWidget {
  const AddInfoRecipe({super.key});

  @override
  State<AddInfoRecipe> createState() => _AddInfoRecipeState();
}

class _AddInfoRecipeState extends State<AddInfoRecipe> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bạn chưa đăng nhập'),
          content: Text('Vui lòng đăng nhập để tiếp tục.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
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

  Future<List<Map<String, dynamic>>> _getLatestRecipes() async {
    if (currentUser == null) {
      return [];
    }

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: currentUser!.uid)
        .orderBy('updateAt', descending: true)
        .limit(4)
        .get();

    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: currentUser != null
          ? Center(
              child: Column(
                children: [
                  Container(
                    height: 350,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Container(
                          height: 150,
                          child: Image.asset('assets/logo_noback.png'),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Text(
                            'Lưu giữ tất cả các công thức đặc biệt của bạn ở cùng 1 nơi',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        Text('Và chia sẻ với tất cả mọi người'),
                        SizedBox(height: 10),
                        UiButton(
                          ontap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AddRecipeScreen()),
                            );
                          },
                          title: 'Viết món mới',
                          weightBT: MediaQuery.of(context).size.width * 0.5,
                          color: Color(0xFFFF7622),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Công thức của bạn',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ManageMyRecipe()),
                                  );
                                },
                                child: Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getLatestRecipes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Lỗi: ${snapshot.error}'));
                            }
                            List<Map<String, dynamic>> recipes =
                                snapshot.data ?? [];

                            if (recipes.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    'Bạn chưa có công thức nào.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: recipes.length,
                              itemBuilder: (context, index) {
                                final recipe = recipes[index];
                                return Container(
                                  child: Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 0),
                                      child: SimpleItemRecipe(
                                        description:
                                            recipe['description'] ?? '',
                                        onTap: () {
                                          // Add your onTap functionality here
                                        },
                                        name: recipe['namerecipe'] ?? '',
                                        star: recipe['rates'].length.toString(),
                                        favorite:
                                            recipe['likes'].length.toString(),
                                        image: recipe['image'] ?? '',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          : Container(
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
                      // Navigate to sign in screen
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
            ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
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

                Navigator.pushNamed(context, '/login');
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: currentUser != null
          ? Center(
            child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách công thức'),
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        return Container(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ItemRecipe(
                                ontap: () {
                                  
                                },
                                name:
                                    'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                                star: '4.3',
                                favorite: '2000',
                                avatar: '',
                                fullname: 'Phạm Duy Đạt',
                                image: 'assets/food_intro.jpg',
                                isFavorite: false,
                                onFavoritePressed: () {
                                  
                                },
                              ),
                            )
                          ),
                        );
                      },
                    ),
                  ],
                )
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
                Text('Tham gia ngay cùng cộng đồng lớn'),
                SizedBox(
                  height: 30,
                ),
                GestureDetector(
                  onTap: () {

                  },
                  child: Text('Đăng nhập ngay'),
                )
              ],
            ),
          )
    );
  }
}
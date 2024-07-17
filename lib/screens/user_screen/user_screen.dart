import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/admin_screen/recipe/admin_recipe.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/screens/user_screen/widgets/ui_container.dart';
import 'package:recipe_app/screens/user_screen/widgets/ui_menu.dart';
import 'package:recipe_app/service/auth_service.dart';
import 'package:recipe_app/service/notification_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  User? currentUser;
  DocumentSnapshot? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      setState(() {
        userProfile = userDoc;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
    print(userProfile!['role']);
  }

  void printName() {
    print(currentUser!.uid);
  }

  AuthService _authService = AuthService();

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NavigateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Center(child: CircularProgressIndicator()))
              : currentUser == null
                  ? Center(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignInScreen()),
                              );
                            },
                            child: Container(
                              height: 100,
                              width: MediaQuery.of(context).size.width * 0.9,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 208, 208, 208),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.account_circle,
                                    size: 50,
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Đăng nhập vào tài khoản'),
                                        Text(
                                            'Lưu và tạo công thức, gửi cooksnap và hơn thế nữa')
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 30,
                          ),
                          Container(

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
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 50,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ProfileUser(
                                        userId: currentUser!.uid,
                                      )),
                            );
                          },
                          child: Container(
                            height: 100,
                            width: MediaQuery.of(context).size.width * 0.9,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 5,
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: ClipOval(
                                    child: Image.network(
                                      userProfile!['avatar'].isNotEmpty
                                          ? userProfile!['avatar']
                                          : 'https://firebasestorage.googleapis.com/v0/b/recipe-app-5a80e.appspot.com/o/profile_images%2F1719150232272?alt=media&token=ea875488-b4bd-43f1-b858-d6eba92e982a',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProfile!['fullname'],
                                        style: TextStyle(
                                            color: Color(0xFFFF7622),
                                            fontSize: 25),
                                      ),
                                      Text('Xem thông tin chi tiết')
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        UIMenu(
                            ontap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ManageMyRecipe()),
                              );
                            },
                            icon: Icons.calculate,
                            title: 'Công thức của bạn'),
                        SizedBox(
                          height: 10,
                        ),
                        UIMenu(
                            ontap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SettingPrivacyScreen()),
                              );
                            },
                            icon: Icons.privacy_tip,
                            title: 'Cài đặt quyền riêng tư'),
                        SizedBox(
                          height: 10,
                        ),
                        UIMenu(
                            ontap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        ChangePasswordScreen()),
                              );
                            },
                            icon: Icons.privacy_tip,
                            title: 'Đổi mật khẩu'),
                        SizedBox(
                          height: 10,
                        ),
                        UIMenu(
                            ontap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SettingNotifyScreen()),
                              );
                            },
                            icon: Icons.notifications,
                            title: 'Cài đặt thông báo'),
                        SizedBox(
                          height: 10,
                        ),
                        if (userProfile!['role'] == 'Quản trị viên')
                          UIMenu(
                              ontap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AdminScreen()),
                                );
                              },
                              icon: Icons.beach_access,
                              title: 'Chức năng quản trị'),
                        if (userProfile!['role'] == 'Quản trị viên')
                          SizedBox(
                            height: 10,
                          ),
                        if (userProfile!['role'] == 'Chuyên gia')
                          
                          UIMenu(
                              ontap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AdminRecipe()),
                                );
                              },
                              icon: Icons.beach_access,
                              title: 'Phê duyệt công thức'),
                        if (userProfile!['role'] == 'Chuyên gia')
                          SizedBox(
                            height: 10,
                          ),
                        UIMenu(
                          ontap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                String password = '';
                                String errorMessage = '';
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: Text('Vô hiệu hóa tài khoản'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Vui lòng nhập mật khẩu để xác nhận vô hiệu hóa tài khoản.'),
                                          SizedBox(height: 10),
                                          TextField(
                                            obscureText: true,
                                            onChanged: (value) {
                                              password = value;
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Nhập mật khẩu',
                                            ),
                                          ),
                                          if (errorMessage.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                errorMessage,
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Hủy'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Vô hiệu hóa'),
                                          onPressed: () async {
                                            try {
                                              UserCredential userCredential =
                                                  await FirebaseAuth.instance
                                                      .signInWithEmailAndPassword(
                                                email: currentUser!.email!,
                                                password: password,
                                              );

                                              await AuthService()
                                                  .disableAccount(
                                                      currentUser!.uid);
                                              await FirebaseAuth.instance
                                                  .signOut();
                                              Navigator.of(context).pop();
                                              Navigator.of(context)
                                                  .pushReplacement(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SignInScreen()),
                                              );
                                            } catch (e) {
                                              setState(() {
                                                errorMessage =
                                                    'Mật khẩu không đúng. Vui lòng thử lại.';
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          icon: Icons.no_accounts,
                          title: 'Vô hiệu hóa tài khoản',
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        UIContainer(
                            ontap: () {
                              _signOut();
                            },
                            color: Colors.red,
                            title: 'Đăng xuất'),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

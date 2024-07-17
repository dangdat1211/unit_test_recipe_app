import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/add_recipe/add_info_recipe.dart';
import 'package:recipe_app/screens/notify_screen/notify_screen.dart';
import 'package:recipe_app/screens/ranking_screen/ranking_screen.dart';
import 'package:recipe_app/screens/screens.dart';


class NavigateScreen extends StatefulWidget {
  const NavigateScreen({super.key});

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    RankingScreen(),
    AddInfoRecipe(),
    NotifyScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.fixed,
        items: [
          TabItem(icon: Icons.home, title: 'Trang chủ'),
          TabItem(icon: Icons.explore, title: 'Khám phá'),
          TabItem(icon: Icons.add, title: 'Đăng tải'),
          TabItem(icon: Icons.notifications, title: 'Thông báo'),
          TabItem(icon: Icons.person, title: 'Hồ sơ'),
        ],
        backgroundColor: Color(0xFFFF7622),
        initialActiveIndex: 0,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

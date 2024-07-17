import 'package:flutter/material.dart';
import 'package:recipe_app/screens/admin_screen/account/admin_account.dart';
import 'package:recipe_app/screens/admin_screen/category/admin_category.dart';
import 'package:recipe_app/screens/admin_screen/ingredient/admin_ingredient.dart';
import 'package:recipe_app/screens/admin_screen/method/admin_method.dart';
import 'package:recipe_app/screens/admin_screen/recipe/admin_recipe.dart';
import 'package:recipe_app/screens/admin_screen/recipe/admin_view_recipe.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trang quản lý'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          _buildAdminTile('Quản lý công thức', Icons.restaurant_menu, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminViewRecipe()),
            );
          }),
          _buildAdminTile('Quản lý nguyên liệu', Icons.inventory, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminIngredients()),
            );
          }),
          _buildAdminTile('Quản lý loại món ăn', Icons.category, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminCateGory()),
            );
          }),
          _buildAdminTile('Quản lý phương pháp nấu', Icons.book, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminMethod()),
            );
          }),
          _buildAdminTile('Tài khoản', Icons.verified_user, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminAccount()),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdminTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: Theme.of(context).primaryColor),
            SizedBox(height: 8.0),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

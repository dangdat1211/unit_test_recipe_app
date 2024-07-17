import 'package:flutter/material.dart';

class AdminCateGory extends StatefulWidget {
  const AdminCateGory({super.key});

  @override
  State<AdminCateGory> createState() => _AdminCateGoryState();
}

class _AdminCateGoryState extends State<AdminCateGory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý loại món ăn'),
      ),
    );
  }
}
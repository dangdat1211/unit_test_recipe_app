import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';

class SnackBarCustom {
  static showbar (BuildContext context,String title) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title,
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: mainColorBackground,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration:
              Duration(seconds: 2), // Giảm thời gian hiển thị xuống 2 giây
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }
}
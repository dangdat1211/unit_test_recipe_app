import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/local_storage_helper.dart';
import 'package:recipe_app/screens/screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    redirectOnbroadingScrren();
  }

  void redirectOnbroadingScrren() async {
    final inFirst = LocalStorageHelper.getValue('inFirst') as bool?;
    await Future.delayed(const Duration(seconds: 2));

    if (inFirst != null && inFirst) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NavigateScreen()),
      );
    } else {
      LocalStorageHelper.setValue('inFirst', true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnbroadingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CircularProgressIndicator();
  }
}

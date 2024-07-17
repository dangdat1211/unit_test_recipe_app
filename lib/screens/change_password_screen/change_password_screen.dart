import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/service/user_service.dart';
import 'package:recipe_app/widgets/input_form.dart';
import 'package:recipe_app/widgets/ui_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  Future<void> _showChangePasswordDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bạn chắc chắn muốn đổi mật khẩu'),
          actions: <Widget>[
            TextButton(
              child: Text('Không'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Có'),
              onPressed: () {
                Navigator.of(context).pop();
                _changePassword();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
  setState(() {
    // Reset error messages
    _currentPasswordError = null;
    _newPasswordError = null;
    _confirmPasswordError = null;

    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      _currentPasswordError = 'Chưa nhập mật khẩu hiện tại';
    }
    if (_newPasswordController.text.isEmpty) {
      _newPasswordError = 'Chưa nhập mật khẩu mới';
    } else if (_newPasswordController.text != _confirmPasswordController.text) {
      _confirmPasswordError = 'Mật khẩu không trùng';
    }
  });

  if (_currentPasswordError == null && _newPasswordError == null && _confirmPasswordError == null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Changing Password'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Please wait...'),
          ],
        ),
      ),
    );

    try {
      UserService userService = UserService();
      await userService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      Navigator.of(context).pop(); 

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Password Changed'),
          content: Text('Your password has been successfully changed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop(); 
      setState(() {
        if(e.code =='weak-password') {
          _newPasswordError = 'Mật khẩu mới quá yếu';
        } else  {
          _currentPasswordError = 'Mật khẩu không chính xác';
        }
        
      });
    }
  }
}

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đổi mật khẩu'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputForm(
              controller: _currentPasswordController,
              focusNode: _currentPasswordFocusNode,
              errorText: _currentPasswordError,
              isPassword: true,
              label: 'Mật khẩu hiện tại',
            ),
            SizedBox(height: 16),
            InputForm(
              controller: _newPasswordController,
              focusNode: _newPasswordFocusNode,
              errorText: _newPasswordError,
              isPassword: true,
              label: 'Mật khẩu mới',
            ),
            SizedBox(height: 16),
            InputForm(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              errorText: _confirmPasswordError,
              isPassword: true,
              label: 'Nhập lại mật khẩu mới',
            ),
            SizedBox(height: 20),
            UiButton(
              ontap: _showChangePasswordDialog, 
              title: 'Đổi mật khẩu', 
              weightBT: MediaQuery.of(context).size.width*0.9, 
              color: mainColor
            ),
          ],
        ),
      ),
    );
  }
}

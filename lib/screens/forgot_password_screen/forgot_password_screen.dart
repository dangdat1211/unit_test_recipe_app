import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/constants/colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        setState(() {
          _emailError = _validateEmail(_emailController.text);
        });
      }
    });
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email không được để trống';
    }
    String pattern = r'^[^@]+@[^@]+\.[^@]+';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  Future<void> _sendResetPasswordLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text;
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        setState(() {
          _emailError = 'Không tìm thấy tài khoản với email này';
        });
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Liên kết đặt lại mật khẩu đã được gửi',
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
    } catch (e) {
      setState(() {
        _emailError = 'Đã xảy ra lỗi. Vui lòng thử lại';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quên mật khẩu'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              
              
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  errorText: _emailError,
                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                      FocusScope.of(context).unfocus();
                        if (_validateEmail(_emailController.text) == null) {
                          _emailError = '';
                          _sendResetPasswordLink();
                        } else {
                          setState(() {
                            _emailError = _validateEmail(_emailController.text);
                          });
                        }
                      },
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : Color(0xFFFF7622),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Gửi lại liên kết đặt lại mật khẩu',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

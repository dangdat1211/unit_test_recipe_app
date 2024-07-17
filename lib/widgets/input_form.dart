import 'package:flutter/material.dart';

class InputForm extends StatefulWidget {
  const InputForm(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.errorText,
      this.onSubmitted,
      this.isPassword = false, required this.label});

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final bool isPassword;
  final String label;
  final Function(String)? onSubmitted;

  @override
  State<InputForm> createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: widget.onSubmitted,
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
        labelText: widget.label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        errorText: widget.errorText,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        labelStyle: TextStyle(fontSize: 16),
        errorStyle: TextStyle(fontSize: 14),  
      ),
      obscureText: widget.isPassword ? _obscureText : false,
    );
  }
}

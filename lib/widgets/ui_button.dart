import 'package:flutter/material.dart';

class UiButton extends StatefulWidget {
  const UiButton(
      {super.key,
      required this.ontap,
      required this.title,
      required this.weightBT,
      required this.color});

  final VoidCallback  ontap;
  final String title;
  final double weightBT;
  final Color color;

  @override
  State<UiButton> createState() => _UiButtonState();
}

class _UiButtonState extends State<UiButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.ontap,
      child: Container(
        height: 50,
        width: widget.weightBT,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            widget.title,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

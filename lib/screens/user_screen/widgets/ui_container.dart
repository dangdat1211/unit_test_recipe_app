import 'package:flutter/material.dart';

class UIContainer extends StatefulWidget {
  const UIContainer({super.key, required this.ontap, required this.title, required this.color});

  final VoidCallback ontap;
  final String title;
  final Color color;

  @override
  State<UIContainer> createState() => _UIContainerState();
}

class _UIContainerState extends State<UIContainer> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.ontap,
      child: Container(
          height: 50,
          width: MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            color: widget.color,
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
          child: Center(
            child: Text(widget.title),
          )),
    );
  }
}

import 'package:flutter/material.dart';

class UIMenu extends StatefulWidget {
  const UIMenu({super.key, required this.ontap, required this.icon, required this.title});

  final VoidCallback ontap;
  final IconData icon;
  final String title;

  @override
  State<UIMenu> createState() => _UIMenuState();
  
}

class _UIMenuState extends State<UIMenu> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.ontap,
      child: Container(
        height: 50,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
            ),
            const SizedBox(
              width: 10,
            ),
            Container(
                width: MediaQuery.of(context).size.width * 0.74,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.title),
                    Icon(Icons.arrow_right)
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

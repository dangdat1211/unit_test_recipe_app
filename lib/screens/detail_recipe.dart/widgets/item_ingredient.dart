import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ItemIngredient extends StatefulWidget {
  const ItemIngredient({super.key, required this.index, required this.title, this.child });

  final String index;
  final String title;
  final Widget? child;

  @override
  State<ItemIngredient> createState() => _ItemIngredientState();
}

class _ItemIngredientState extends State<ItemIngredient> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 166, 115),
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Text(widget.index),
              ),
            ),
            SizedBox(
              width: 10,
            ),
            Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                      // color: Color.fromARGB(255, 255, 166, 115),
                      borderRadius: BorderRadius.circular(16)),
                  padding: EdgeInsets.only(top: 0, bottom: 0, left: 5, right: 5),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                if (widget.child != null) widget.child!,
              ],
            ),
          ],
        ),
      ],
    );
  }
}

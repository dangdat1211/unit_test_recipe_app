import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ItemStep extends StatefulWidget {
  const ItemStep({
    Key? key,
    required this.index,
    required this.title,
    this.child,
  }) : super(key: key);

  final String index;
  final String title;
  final Widget? child;

  @override
  State<ItemStep> createState() => _ItemStepState();
}

class _ItemStepState extends State<ItemStep> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 166, 115),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(widget.index),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _isExpanded 
                          ? Text(widget.title) 
                          : Text(
                          widget.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                            
                          
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Color.fromARGB(255, 255, 166, 115),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  if (_isExpanded && widget.child != null) ...[
                    SizedBox(height: 10),
                    widget.child!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
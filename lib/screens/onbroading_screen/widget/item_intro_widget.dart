import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ItemIntroWidget extends StatelessWidget {
  const ItemIntroWidget({
    super.key,
    required this.image,
    required this.title,
    required this.decription,
  });

  final String image;
  final String title;
  final String decription;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200, 
          height: 200, 
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5), 
                spreadRadius: 5, 
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(8.0),
            child: Image.asset(
              image,
              width: 200, 
              height: 200, 
              fit: BoxFit.cover, 
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                decription,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w100),
              )
            ],
          ),
        ),
      ],
    );
  }
}

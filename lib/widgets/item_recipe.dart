import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/screens/screens.dart';

class ItemRecipe extends StatefulWidget {
  const ItemRecipe({
    super.key,
    required this.name,
    required this.star,
    required this.favorite,
    required this.avatar,
    required this.fullname,
    required this.image,
    required this.ontap,
    required this.isFavorite,
    required this.onFavoritePressed,
  });

  final VoidCallback ontap;
  final String name;
  final String star;
  final String favorite;
  final String avatar;
  final String fullname;
  final String image;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;

  @override
  State<ItemRecipe> createState() => _ItemRecipeState();
}

class _ItemRecipeState extends State<ItemRecipe> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    widget.onFavoritePressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.ontap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8 + 2,
        height: 142,
        decoration: BoxDecoration(
          color: mainColorBackground,
          border: Border.all(width: 1, color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.55,
              height: 142,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    width: 1,
                    color: Colors.grey,
                  ),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star, color: Color.fromARGB(255, 255, 230, 0), shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],),
                                SizedBox(width: 4),
                                Text(widget.star),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.favorite, color: Colors.red),
                                SizedBox(width: 4),
                                Text(widget.favorite),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(widget.avatar),
                              radius: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.fullname,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              height: 142,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(9),
                        bottomRight: Radius.circular(9),
                      ),
                      child: Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Icon(
                        Icons.favorite,
                        size: 36.0,
                        color: _isFavorite ? Colors.red : Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

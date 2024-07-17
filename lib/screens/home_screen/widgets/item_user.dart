import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';

class ItemUser extends StatefulWidget {
  const ItemUser(
      {super.key,
      required this.avatar,
      required this.fullname,
      required this.username,
      required this.recipe,
      required this.follow, required this.ontap, required this.clickFollow});

  final VoidCallback ontap;
  final String avatar;
  final String fullname;
  final String username;
  final String recipe;
  final bool follow;
  final VoidCallback clickFollow;

  @override
  State<ItemUser> createState() => _ItemUserState();
}

class _ItemUserState extends State<ItemUser> {
  late bool isFollowing;

  @override
  void initState() {
    super.initState();
    isFollowing = widget.follow;
  }

  void toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
      widget.clickFollow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.ontap,
      child: Card(
        color: cardBack,
        child: Container(
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.avatar),
              ),
              Text(
                (widget.fullname),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                '@' + widget.username,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(widget.recipe + ' công thức'),
              GestureDetector(
                onTap: () {
                  toggleFollow();
                },
                child: Container(
                    height: 30,
                    width: 100,
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                        child: !isFollowing
                            ? Text(
                                'Theo dõi ngay',
                                style: TextStyle(
                                  color: Color(0xFFFF7622),
                                ),
                              )
                            : Text(
                                'Đã theo dõi',
                                style: TextStyle(
                                  color: Color(0xFFFF7622),
                                ),
                              ))),
              )
            ],
          ),
        ),
      ),
    );
  }
}

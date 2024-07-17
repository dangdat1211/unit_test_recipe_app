import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/service/comment_service.dart';
import 'package:recipe_app/models/comment_model.dart';

class CommentScreen extends StatefulWidget {
  final String recipeId;
  final String userId;
  final bool autoFocus;

  const CommentScreen({
    Key? key,
    required this.recipeId,
    required this.userId,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<CommentModel> comments = [];
  final TextEditingController _commentController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? currentUserData;
  bool isLoadingComments = true;
  bool isLoadingUser = true;
  final FocusNode _focusNode = FocusNode();

  final CommentService _commentService = CommentService();

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUser();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        setState(() {
          currentUserData = userSnapshot.data() as Map<String, dynamic>?;
          isLoadingUser = false;
        });
      } else {
        setState(() {
          isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final loadedComments = await _commentService.getComments(widget.recipeId);
      setState(() {
        comments = loadedComments;
        isLoadingComments = false;
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  void _addComment() async {
    if (currentUser != null) {
      final newComment = _commentController.text.trim();
      if (newComment.isNotEmpty) {
        await _commentService.addComment(widget.recipeId, currentUser!.uid, newComment);
        _loadComments();
        _commentController.clear();
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Bạn chưa đăng nhập'),
            content: Text('Vui lòng đăng nhập để tiếp tục.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
                child: Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Hủy'),
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteComment(String commentId, int index) async {
    await _commentService.deleteComment(commentId);
    setState(() {
      comments.removeAt(index);
    });
  }

  void _confirmDeleteComment(BuildContext context, String commentId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa bình luận'),
        content: Text('Bạn có chắc chắn muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _deleteComment(commentId, index);
              Navigator.of(context).pop();
            },
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Cơm rượu nếp than'),
      ),
      body: Stack(
        children: [
          if (isLoadingComments)
            Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: EdgeInsets.only(bottom: 80.0),
              child: comments.isEmpty
                  ? Center(
                      child: Text('Không có bình luận nào.'),
                    )
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final String formattedDate =
                            DateFormat('dd/MM/yyyy HH:mm').format(comment.createdAt);

                        return Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(comment.avatarUrl),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.author),
                                    Text(formattedDate),
                                    Text(comment.content),
                                  ],
                                ),
                              ),
                              PopupMenuButton<int>(
                                icon: Icon(Icons.more_vert),
                                onSelected: (item) =>
                                    _onSelected(context, item, comment, index),
                                itemBuilder: (context) => [
                                  PopupMenuItem<int>(value: 0, child: Text('Xóa')),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          if (currentUser != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    isLoadingUser
                        ? CircularProgressIndicator()
                        : CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(currentUserData?['avatar'] ?? ''),
                          ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Bình luận ngay',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.fromLTRB(20, 10, 10, 10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          if (currentUser == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
                child: Container(
                  height: 100,
                  child: Center(child: Text('Đăng nhập ngay để bình luận . Tại đây')),
                ),
              ),
            )
        ],
      ),
    );
  }

  void _onSelected(BuildContext context, int item, CommentModel comment, int index) {
    switch (item) {
      case 0:
        if (_commentService.canDeleteComment(currentUser!.uid, comment.userId, widget.userId)) {
          _confirmDeleteComment(context, comment.id, index);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Không đủ thẩm quyền'),
              content: Text('Bạn chỉ có thể xóa bình luận của bạn hoặc bình luận từ công thức của bạn'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        break;
    }
  }
}
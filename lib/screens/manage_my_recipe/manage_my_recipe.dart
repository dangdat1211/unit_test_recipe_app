import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/add_recipe/edit_recipe.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';

class ManageMyRecipe extends StatefulWidget {
  const ManageMyRecipe({super.key});

  @override
  State<ManageMyRecipe> createState() => _ManageMyRecipeState();
}

class _ManageMyRecipeState extends State<ManageMyRecipe>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sortOption = 'Mới nhất';
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePopupMenuSelection(String value, String recipeId) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditRecipeScreen(
                    recipeId: recipeId,
                  )),
        );
        break;
      case 'delete':
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Xác nhận xóa'),
              content: Text('Bạn có chắc chắn muốn xóa công thức này không?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Xóa'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          await _deleteRecipe(recipeId);
        }
        break;
      case 'hide':
        await _hideRecipe(recipeId);
        break;
      case 'show':
        await _showRecipe(recipeId);
        break;
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.delete(
          FirebaseFirestore.instance.collection('recipes').doc(recipeId));

      QuerySnapshot rateSnapshots = await FirebaseFirestore.instance
          .collection('rates')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in rateSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot commentSnapshots = await FirebaseFirestore.instance
          .collection('comments')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in commentSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot favoriteSnapshots = await FirebaseFirestore.instance
          .collection('favorites')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in favoriteSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot stepSnapshots = await FirebaseFirestore.instance
          .collection('steps')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in stepSnapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      SnackBarCustom.showbar(context, 'Xóa thành công');

      setState(() {});
    } catch (e) {
      print('Lỗi khi xóa công thức và dữ liệu liên quan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Có lỗi xảy ra khi xóa công thức và dữ liệu liên quan')),
      );
    }
  }

  Future<void> _hideRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': true,
      });
      SnackBarCustom.showbar(context, 'Công thức đã được ẩn');
      setState(() {});
    } catch (e) {
      print('Lỗi khi ẩn công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi ẩn công thức')),
      );
    }
  }

  Future<void> _showRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': false,
      });
      SnackBarCustom.showbar(context, 'Công thức đã được hiện');
      setState(() {});
    } catch (e) {
      print('Lỗi khi hiện công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi hiện công thức')),
      );
    }
  }

  Widget buildRecipeList(String status) {
    Query recipesQuery = FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: currentUser!.uid);

    if (status.isNotEmpty) {
      recipesQuery = recipesQuery.where('status', isEqualTo: status);
    }

    switch (sortOption) {
      case 'Mới nhất':
        recipesQuery = recipesQuery.orderBy('updateAt', descending: true);
        break;
      case 'Cũ nhất':
        recipesQuery = recipesQuery.orderBy('updateAt', descending: false);
        break;
      case 'Được yêu thích nhiều nhất':
        recipesQuery = recipesQuery.orderBy('favoriteCount', descending: true);
        break;
      case 'Được yêu thích ít nhất':
        recipesQuery = recipesQuery.orderBy('favoriteCount', descending: false);
        break;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: recipesQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Đã xảy ra lỗi');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var recipes = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((recipe) => recipe['namerecipe']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        if (recipes.isEmpty) {
          return Center(child: Text('Không có công thức nào'));
        }

        int totalPages = (recipes.length / _itemsPerPage).ceil();
        int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > recipes.length) endIndex = recipes.length;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: endIndex - startIndex,
                itemBuilder: (context, index) {
                  var recipe = recipes[startIndex + index];
                  var recipeId = snapshot.data!.docs[startIndex + index].id;
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailReCipe(
                              recipeId: recipeId, userId: currentUser!.uid),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        width: 80,
                        height: 80,
                        child: Image.network(
                          recipe['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        recipe['namerecipe'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['description'],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            'Trạng thái: ${recipe['status']}',
                            style: TextStyle(
                              color: getStatusColor(recipe['status']),
                            ),
                          ),
                          Text(
                            recipe['hidden'] ? 'Đang ẩn' : '',
                            style: TextStyle(
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handlePopupMenuSelection(value, recipeId),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Sửa'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Xóa'),
                          ),
                          PopupMenuItem<String>(
                            value: recipe['hidden'] ? 'show' : 'hide',
                            child: Text(recipe['hidden'] ? 'Hiện' : 'Ẩn'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        : null,
                  ),
                  Text('Trang $_currentPage / $totalPages'),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đợi phê duyệt':
        return Colors.orange;
      case 'Đã được phê duyệt':
        return Colors.green;
      case 'Bị từ chối':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý công thức'),
        centerTitle: true,
        bottom: TabBar(
          dividerColor: Colors.transparent,
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đợi phê duyệt'),
            Tab(text: 'Đã được phê duyệt'),
            Tab(text: 'Bị từ chối'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 1; // Reset to first page when searching
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isDense: true,
                        value: sortOption,
                        icon: Icon(Icons.arrow_drop_down, size: 20),
                        style: TextStyle(color: Colors.black, fontSize: 15),
                        onChanged: (String? newValue) {
                          setState(() {
                            sortOption = newValue!;
                            _currentPage = 1; // Reset to first page when sorting
                          });
                        },
                        items: <String>[
                          'Mới nhất',
                          'Cũ nhất',
                          'Yêu thích nhiều',
                          'Yêu thích ít'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildRecipeList(''),
                buildRecipeList('Đợi phê duyệt'),
                buildRecipeList('Đã được phê duyệt'),
                buildRecipeList('Bị từ chối'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
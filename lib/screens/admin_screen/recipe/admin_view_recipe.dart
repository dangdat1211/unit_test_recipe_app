import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';

class AdminViewRecipe extends StatefulWidget {
  const AdminViewRecipe({super.key});

  @override
  State<AdminViewRecipe> createState() => _AdminViewRecipeState();
}

class _AdminViewRecipeState extends State<AdminViewRecipe>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sortOption = 'Mới nhất';
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  Map<String, List<String>> selectedFilters = {
    'difficulty': [],
    'time': [],
    'method': [],
  };

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
      case 'approve':
        await _approveRecipe(recipeId);
        break;
      case 'reject':
        await _rejectRecipe(recipeId);
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
    }
  }

  Future<void> _approveRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'status': 'Đã được phê duyệt',
      });
      SnackBarCustom.showbar(context, 'Công thức đã được phê duyệt');
      setState(() {});
    } catch (e) {
      print('Lỗi khi phê duyệt công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi phê duyệt công thức')),
      );
    }
  }

  Future<void> _rejectRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'status': 'Bị từ chối',
      });
      SnackBarCustom.showbar(context, 'Công thức đã bị từ chối');
      setState(() {});
    } catch (e) {
      print('Lỗi khi từ chối công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi từ chối công thức')),
      );
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

  Widget buildRecipeList(String status) {
    Query recipesQuery = FirebaseFirestore.instance.collection('recipes');

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
      case 'Đánh giá cao nhất':
        recipesQuery = recipesQuery.orderBy('rateCount', descending: true);
        break;
      case 'Yêu thích nhiều nhất':
        recipesQuery = recipesQuery.orderBy('likeCount', descending: true);
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
            .where((recipe) {
          bool nameMatch = recipe['namerecipe']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

          bool ingredientMatch = false;
          if (recipe['ingredients'] != null && recipe['ingredients'] is List) {
            ingredientMatch = (recipe['ingredients'] as List).any((ingredient) =>
                ingredient
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()));
          }

          bool difficultyMatch = true;
          if (selectedFilters['difficulty']!.isNotEmpty) {
            difficultyMatch =
                selectedFilters['difficulty']!.contains(recipe['level']);
          }

          bool methodMatch = true;
          if (selectedFilters['method']!.isNotEmpty) {
            methodMatch = selectedFilters['method']!.any((method) =>
                recipe['namerecipe']
                    .toString()
                    .toLowerCase()
                    .contains(method.toLowerCase()));
          }

          bool timeMatch = true;
          if (selectedFilters['time']!.isNotEmpty) {
            int recipeCookingTime = int.tryParse(
                    recipe['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
                0;
            timeMatch = selectedFilters['time']!.any((timeFilter) {
              if (timeFilter == '< 30 phút') {
                return recipeCookingTime < 30;
              } else if (timeFilter == '30-60 phút') {
                return recipeCookingTime >= 30 && recipeCookingTime <= 60;
              } else if (timeFilter == '> 60 phút') {
                return recipeCookingTime > 60;
              }
              return false;
            });
          }

          return (nameMatch || ingredientMatch) &&
              difficultyMatch &&
              methodMatch &&
              timeMatch;
        }).toList();

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
                              recipeId: recipeId, userId: recipe['userID']),
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
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(recipe['userID'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Text('Đang tải...');
                              }
                              if (snapshot.hasError) {
                                return Text('Lỗi: ${snapshot.error}');
                              }
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Text('Người tạo: Không xác định');
                              }
                              var userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              return Text(
                                  'Người tạo: ${userData['fullname'] ?? 'Không xác định'}');
                            },
                          ),
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
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handlePopupMenuSelection(value, recipeId),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'approve',
                            child: Text('Phê duyệt'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'reject',
                            child: Text('Từ chối'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Xóa'),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Lọc và Sắp xếp kết quả'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: sortOption,
                      onChanged: (String? newValue) {
                        setState(() {
                          sortOption = newValue!;
                        });
                      },
                      items: <String>['Mới nhất', 'Cũ nhất', 'Đánh giá cao nhất', 'Yêu thích nhiều nhất']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text('Độ khó:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('difficulty', ['Dễ', 'Trung bình', 'Khó'], setState),
                    SizedBox(height: 10),
                    Text('Mốc thời gian:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('time', ['< 30 phút', '30-60 phút', '> 60 phút'], setState),
                    SizedBox(height: 10),
                    Text('Phương pháp chế biến:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('method', ['Rán', 'Xào', 'Nướng', 'Hấp'], setState),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                
                TextButton(
                  child: Text('Áp dụng'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentPage = 1;
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCheckboxes(String filterType, List<String> options, StateSetter setState) {
    return options.map((option) {
      return CheckboxListTile(
        title: Text(option),
        value: selectedFilters[filterType]!.contains(option),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedFilters[filterType]!.add(option);
            } else {
              selectedFilters[filterType]!.remove(option);
            }
          });
        },
      );
    }).toList();
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
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _showFilterDialog,
                  child: Text('Lọc'),
                ),
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
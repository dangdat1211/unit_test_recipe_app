import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/admin_screen/ingredient/edit_ingredient.dart';
import 'package:recipe_app/screens/admin_screen/ingredient/add_ingredient.dart';

class AdminIngredients extends StatefulWidget {
  const AdminIngredients({Key? key}) : super(key: key);

  @override
  State<AdminIngredients> createState() => _AdminIngredientsState();
}

class _AdminIngredientsState extends State<AdminIngredients> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nguyên liệu'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm nguyên liệu...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(width: 1, color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1; // Reset to first page when searching
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ingredients')
                  .orderBy(_sortBy, descending: !_sortAscending)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var ingredients = snapshot.data!.docs
                    .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                    .where((ingredient) =>
                        ingredient['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        ingredient['keysearch'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                _totalItems = ingredients.length;
                int totalPages = (_totalItems / _itemsPerPage).ceil();

                int startIndex = (_currentPage - 1) * _itemsPerPage;
                int endIndex = startIndex + _itemsPerPage;
                if (endIndex > _totalItems) endIndex = _totalItems;

                var paginatedIngredients = ingredients.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: paginatedIngredients.length,
                        itemBuilder: (context, index) {
                          var data = paginatedIngredients[index];

                          return ListTile(
                            leading: Image.network(data['image'],
                                width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(data['name']),
                            subtitle: Text(data['keysearch']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditIngredient(ingredientId: data['id']),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _showDeleteConfirmationDialog(
                                      data['id'], data['name']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    _buildPaginationControls(totalPages),
                    SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngredient(),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Thêm nguyên liệu'),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
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
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sắp xếp theo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tên'),
                leading: Radio<String>(
                  value: 'name',
                  groupValue: _sortBy,
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = value!;
                      _sortAscending = true;
                      _currentPage = 1; // Reset to first page when sorting
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Ngày tạo'),
                leading: Radio<String>(
                  value: 'createAt',
                  groupValue: _sortBy,
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = value!;
                      _sortAscending = false;
                      _currentPage = 1; // Reset to first page when sorting
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String ingredientId, String ingredientName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa nguyên liệu "$ingredientName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xóa'),
              onPressed: () {
                _deleteIngredient(ingredientId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteIngredient(String ingredientId) {
    FirebaseFirestore.instance
        .collection('ingredients')
        .doc(ingredientId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa nguyên liệu thành công')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi xóa nguyên liệu')),
      );
    });
  }
}
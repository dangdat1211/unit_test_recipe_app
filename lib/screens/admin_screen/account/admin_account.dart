import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';

class AdminAccount extends StatefulWidget {
  const AdminAccount({super.key});

  @override
  State createState() => _AdminAccountState();
}

class _AdminAccountState extends State<AdminAccount> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'fullname';
  bool _isAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý tài khoản'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
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
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 1; // Reset to first page when searching
                    });
                  },
                ),
              ),
              TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                tabs: [
                  Tab(text: 'Đang hoạt động'),
                  Tab(text: 'Vô hiệu hóa'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountList(true),
          _buildAccountList(false),
        ],
      ),
    );
  }

  Widget _buildAccountList(bool isActive) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: isActive)
          .orderBy(_sortBy, descending: !_isAscending)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có tài khoản nào'));
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['fullname'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 data['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(child: Text('Không tìm thấy kết quả'));
        }

        _totalItems = filteredDocs.length;
        int totalPages = (_totalItems / _itemsPerPage).ceil();

        int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > _totalItems) endIndex = _totalItems;

        var paginatedDocs = filteredDocs.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: ListView(
                children: paginatedDocs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(data['avatar'] ?? ''),
                    ),
                    title: Text(data['fullname'] ?? ''),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: Switch(
                      value: data['status'],
                      onChanged: (bool value) {
                        _showConfirmationDialog(document.id, value);
                      },
                    ),
                    onTap: () {
                      _navigateToUserDetail(document.id);
                    },
                  );
                }).toList(),
              ),
            ),
            _buildPaginationControls(totalPages),
          ],
        );
      },
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

  void _showFilterDialog() {
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
                leading: Radio(
                  value: 'fullname',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value.toString();
                      _currentPage = 1; // Reset to first page when sorting
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
              ListTile(
                title: Text('Email'),
                leading: Radio(
                  value: 'email',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value.toString();
                      _currentPage = 1; // Reset to first page when sorting
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(_isAscending ? 'Tăng dần' : 'Giảm dần'),
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _currentPage = 1; // Reset to first page when changing sort order
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String documentId, bool newValue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận'),
          content: Text('Bạn có chắc chắn muốn ${newValue ? "kích hoạt" : "vô hiệu hóa"} tài khoản này?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xác nhận'),
              onPressed: () {
                Navigator.of(context).pop();
                _toggleAccountStatus(documentId, newValue);
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleAccountStatus(String documentId, bool isActive) {
    FirebaseFirestore.instance.collection('users').doc(documentId).update({
      'status': isActive,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái tài khoản thành công')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái tài khoản: $error')),
      );
    });
  }

  void _navigateToUserDetail(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileUser(userId: userId),
      ),
    );
  }
}
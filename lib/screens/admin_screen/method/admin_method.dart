import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/admin_screen/method/add_method.dart';
import 'package:recipe_app/screens/admin_screen/method/edit_method.dart';

class AdminMethod extends StatefulWidget {
  const AdminMethod({super.key});

  @override
  State<AdminMethod> createState() => _AdminMethodState();
}

class _AdminMethodState extends State<AdminMethod> {
  String _searchQuery = '';
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý phương pháp nấu'),
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
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phương pháp...',
                prefixIcon:
                    Icon(Icons.search, size: 20), // Giảm kích thước icon
                contentPadding: EdgeInsets.symmetric(
                    vertical: 0, horizontal: 10), // Giảm padding
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(20), // Bo tròn góc nhiều hơn
                  borderSide: BorderSide(
                      width: 1, color: Colors.grey), // Đường viền mỏng hơn
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      width: 1, color: Theme.of(context).primaryColor),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cookingmethods')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var methods = snapshot.data!.docs
                    .map((doc) =>
                        {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                    .where((method) =>
                        method['name']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        method['keysearch']
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

                methods.sort((a, b) {
                  if (_sortBy == 'name') {
                    return _sortOrder == 'asc'
                        ? a['name'].toString().compareTo(b['name'].toString())
                        : b['name'].toString().compareTo(a['name'].toString());
                  } else if (_sortBy == 'createAt') {
                    var aDate = a['createAt'] as Timestamp;
                    var bDate = b['createAt'] as Timestamp;
                    return _sortOrder == 'asc'
                        ? aDate.compareTo(bDate)
                        : bDate.compareTo(aDate);
                  }
                  return 0;
                });

                return ListView.builder(
                  itemCount: methods.length,
                  itemBuilder: (context, index) {
                    var data = methods[index];
                    return ListTile(
                      leading: Image.network(data['image'],
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(data['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Key search: ${data['keysearch']}'),
                          Text('Ngày tạo: ${_formatDateTime((data['createAt'] as Timestamp).toDate())}'),
                        ],
                      ),
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
                                      EditMethod(methodId: data['id']),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMethod()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
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
                title: Text('Tên (A-Z)'),
                leading: Radio<String>(
                  value: 'name_asc',
                  groupValue: '${_sortBy}_${_sortOrder}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'name';
                      _sortOrder = 'asc';
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Tên (Z-A)'),
                leading: Radio<String>(
                  value: 'name_desc',
                  groupValue: '${_sortBy}_${_sortOrder}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'name';
                      _sortOrder = 'desc';
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Mới nhất'),
                leading: Radio<String>(
                  value: 'createAt_desc',
                  groupValue: '${_sortBy}_${_sortOrder}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'createAt';
                      _sortOrder = 'desc';
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Cũ nhất'),
                leading: Radio<String>(
                  value: 'createAt_asc',
                  groupValue: '${_sortBy}_${_sortOrder}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'createAt';
                      _sortOrder = 'asc';
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

  void _showDeleteConfirmationDialog(String methodId, String methodName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa phương pháp "$methodName"?'),
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
                _deleteMethod(methodId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMethod(String methodId) {
    FirebaseFirestore.instance
        .collection('cookingmethods')
        .doc(methodId)
        .delete()
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa phương pháp nấu thành công')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi xóa phương pháp nấu')),
      );
    });
  }
}

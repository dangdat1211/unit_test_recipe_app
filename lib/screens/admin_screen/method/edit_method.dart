import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditMethod extends StatefulWidget {
  final String methodId;
  const EditMethod({Key? key, required this.methodId}) : super(key: key);

  @override
  State<EditMethod> createState() => _EditMethodState();
}

class _EditMethodState extends State<EditMethod> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _keySearchController;
  File? _image;
  String? _currentImageUrl;
  final picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _keySearchController = TextEditingController();
    _loadMethodData();
  }

  Future<void> _loadMethodData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('cookingmethods')
          .doc(widget.methodId)
          .get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['name'];
        _keySearchController.text = data['keysearch'];
        _currentImageUrl = data['image'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi khi tải dữ liệu: $e'),
            backgroundColor: Colors.red),
      );
    }
    setState(() => _isLoading = false);
  }

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<String> uploadImage() async {
    if (_image == null) return _currentImageUrl ?? '';

    final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('cooking_method_images')
        .child('$fileName.jpg');

    await storageRef.putFile(_image!);
    return await storageRef.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa phương pháp nấu'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _image != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_image!,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover),
                                    )
                                  : _currentImageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                              _currentImageUrl!,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover),
                                        )
                                      : Container(
                                          height: 200,
                                          width: 600,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                              SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: getImage,
                                icon: Icon(Icons.photo_library),
                                label: Text('Chọn ảnh mới'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên phương pháp',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.food_bank),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tên phương pháp';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _keySearchController,
                        decoration: InputDecoration(
                          labelText: 'Từ khóa tìm kiếm',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập từ khóa tìm kiếm';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _updateMethod,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Cập nhật phương pháp nấu',
                              style: TextStyle(fontSize: 18)),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _updateMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String imageUrl = await uploadImage();

      FirebaseFirestore.instance
          .collection('cookingmethods')
          .doc(widget.methodId)
          .update({
        'name': _nameController.text,
        'keysearch': _keySearchController.text,
        'image': imageUrl,
        'updateAt': FieldValue.serverTimestamp(),
      }).then((_) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cập nhật phương pháp nấu thành công')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keySearchController.dispose();
    super.dispose();
  }
}

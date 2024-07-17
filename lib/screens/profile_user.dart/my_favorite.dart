import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/profile_user.dart/widgets/view_item.dart';
import 'package:recipe_app/service/rate_service.dart';

class MyFavorite extends StatefulWidget {
  final String userId;
  const MyFavorite({super.key, required this.userId});

  @override
  State<MyFavorite> createState() => _MyFavoriteState();
}

class _MyFavoriteState extends State<MyFavorite> {
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('favorites');
  
  int _currentPage = 1;
  static const int _itemsPerPage = 6;
  List<Map<String, dynamic>> _allData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    _allData = await _getData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _getData() async {
    QuerySnapshot querySnapshot =
        await _collectionRef.where('userId', isEqualTo: widget.userId).get();
    List<String> favoriteRecipeIds = querySnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['recipeId'] as String)
        .toList();
    
    List<Map<String, dynamic>> recipes = [];
    for (String recipeId in favoriteRecipeIds) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;

        if (recipeData['status'] == "Đã được phê duyệt" && recipeData['hidden'] == false) {
          recipeData['id'] = doc.id; 
          recipeData['averageRating'] = await RateService().getAverageRating(doc.id);
          recipes.add(recipeData);
        }
      }
    }

    return recipes;
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(dateTime); 
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _allData.length) endIndex = _allData.length;
    
    List<Map<String, dynamic>> currentPageData = _allData.sublist(startIndex, endIndex);
    
    int totalPages = (_allData.length / _itemsPerPage).ceil();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Column(
          children: [
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: currentPageData.length,
              itemBuilder: (context, index) {
                final item = currentPageData[index];
                List<String> likedList = List<String>.from(item['likes'] ?? []);
                return ViewItem(
                  image: item['image'] ??
                      'https://static.vinwonders.com/production/mon-ngon-ha-dong-4.jpeg',
                  rate: item['averageRating'].toString(),
                  like: likedList.length.toString(),
                  date: _formatTimestamp(item['createAt']),
                  title: item['namerecipe'] ?? 'Com ngon',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailReCipe(
                          recipeId: item['id'], 
                          userId: item['userID'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            SizedBox(height: 20),
            Row(
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
          ],
        ),
      ),
    );
  }
}
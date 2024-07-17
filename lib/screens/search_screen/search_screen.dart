import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/search_screen/search_user_screen.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSearchTerm;
  const SearchScreen({super.key, this.initialSearchTerm});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResultsWithUserData = [];
  bool isLoading = false;
  String currentSortOption = 'Mới nhất';

  User? currentUser = FirebaseAuth.instance.currentUser;

  Map<String, List<String>> selectedFilters = {
    'difficulty': [],
    'time': [],
    'method': [],
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    if (widget.initialSearchTerm != null) {
      _onSearchSubmitted(widget.initialSearchTerm!);
    }
  }

  void _onSearchSubmitted(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('status', isEqualTo: 'Đã được phê duyệt')
          .get();

      var filteredDocs = snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['hidden'] == false;
      }).toList();

      searchResultsWithUserData = [];

      for (var recipeDoc in filteredDocs) {
        var recipeData = recipeDoc.data() as Map<String, dynamic>;
        var recipeId = recipeDoc.id;

        var userId = recipeData['userID'];

        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        var userData = userDoc.data();

        User? currentUser = FirebaseAuth.instance.currentUser;

        if (userData != null) {
          bool isFavorite = await FavoriteService().isRecipeFavorite(recipeId,);

          bool nameMatch = recipeData['namerecipe']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());

          bool ingredientMatch = false;
          if (recipeData['ingredients'] != null &&
              recipeData['ingredients'] is List) {
            ingredientMatch = (recipeData['ingredients'] as List).any(
                (ingredient) => ingredient
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()));
          }

          bool difficultyMatch = true;
          if (selectedFilters['difficulty']!.isNotEmpty) {
            difficultyMatch = selectedFilters['difficulty']!.contains(recipeData['level']);
          }

          bool methodMatch = true;
          if (selectedFilters['method']!.isNotEmpty) {
            methodMatch = selectedFilters['method']!.any((method) =>
                recipeData['namerecipe']
                    .toString()
                    .toLowerCase()
                    .contains(method.toLowerCase()));
          }

          bool timeMatch = true;
          if (selectedFilters['time']!.isNotEmpty) {
            int recipeCookingTime = int.tryParse(recipeData['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            print(recipeCookingTime);
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

          if ((nameMatch || ingredientMatch) && difficultyMatch && methodMatch && timeMatch) {
            searchResultsWithUserData.add({
              'recipe': recipeData,
              'user': userData,
              'isFavorite': isFavorite,
              'recipeId': recipeId,
            });
          }
        }
      }

      // Sắp xếp kết quả
      searchResultsWithUserData.sort((a, b) {
        switch (currentSortOption) {
          case 'Đánh giá cao nhất':
            return (b['recipe']['rates'] as List).length.compareTo((a['recipe']['rates'] as List).length);
          case 'Yêu thích nhiều nhất':
            return (b['recipe']['likes'] as List).length.compareTo((a['recipe']['likes'] as List).length);
          case 'Mới nhất':
          default:
            return (b['recipe']['createAt'] as Timestamp).compareTo(a['recipe']['createAt'] as Timestamp);
        }
      });

      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResultsWithUserData.clear();
    });
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
                      value: currentSortOption,
                      onChanged: (String? newValue) {
                        setState(() {
                          currentSortOption = newValue!;
                        });
                      },
                      items: <String>['Mới nhất', 'Đánh giá cao nhất', 'Yêu thích nhiều nhất']
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
                    _applyFiltersAndSort();
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

  void _applyFiltersAndSort() {
    _onSearchSubmitted(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
          ),
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _onSearchSubmitted(_searchController.text);
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : searchResultsWithUserData.isNotEmpty
              ? Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 21.0, right: 22),
                        child: Container(
                          child: ListView.builder(
                            itemCount: searchResultsWithUserData.length,
                            itemBuilder: (context, index) {
                              final recipeWithUser = searchResultsWithUserData[index];
                              final recipe = recipeWithUser['recipe'];
                              final user = recipeWithUser['user'];
                              final isFavorite = recipeWithUser['isFavorite'];
                              final recipeId = recipeWithUser['recipeId'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ItemRecipe(
                                  name: recipe['namerecipe'],
                                  star: recipe['rates'].length.toString(),
                                  favorite: recipe['likes'].length.toString(),
                                  avatar: user['avatar'],
                                  fullname: user['fullname'],
                                  image: recipe['image'],
                                  ontap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailReCipe(recipeId: recipeId, userId: recipe['userID'],),
                                      ),
                                    );
                                  },
                                  isFavorite: isFavorite,
                                  onFavoritePressed: () {
                                    FavoriteService().toggleFavorite(context, recipeId, recipe['userID'], );
                                    _onSearchSubmitted(_searchController.text);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchUserScreen(),
                          ),
                        );
                      },
                      child: Text('Tìm kiếm người dùng'),
                    ),
                    Center(
                      child: Text('Không có kết quả tìm kiếm'),
                    ),
                  ],
                ),
    );
  }
}
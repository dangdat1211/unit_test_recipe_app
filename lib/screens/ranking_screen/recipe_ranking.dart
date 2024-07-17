import 'package:flutter/material.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/service/rate_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/constants/colors.dart'; // Thêm import này

class RecipeRanking extends StatefulWidget {
  const RecipeRanking({super.key});

  @override
  State<RecipeRanking> createState() => _RecipeRankingState();
}

class _RecipeRankingState extends State<RecipeRanking> {
  String dropdownValue = 'Lượt thích cao nhất';
  List<Map<String, dynamic>> recipesWithUserData = [];
  bool isLoading = false;

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await FirebaseFirestore.instance.collection('recipes').where('status', isEqualTo: 'Đã được phê duyệt').get();

    var filteredDocs = snapshot.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['hidden'] == false;
    }).toList();

    final recipes = filteredDocs;

    recipesWithUserData = [];

    for (var recipeDoc in recipes) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id;

      var userId = recipeData['userID'];

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var userData = userDoc.data();
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (userData != null) {
        recipeData['recipeId'] = recipeId;

        bool isFavorite = await FavoriteService().isRecipeFavorite(recipeId,);
        
        var ratingData = await RateService().fetchAverageRating(recipeId, currentUser!.uid);

        recipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
          'isFavorite': isFavorite,
          'avgRating': ratingData['avgRating'],
          'ratingCount': ratingData['ratingCount'],
        });
      }
    }

    _sortRecipes();

    setState(() {
      isLoading = false;
    });
  }

  void _sortRecipes() {
    if (dropdownValue == 'Lượt thích cao nhất') {
      recipesWithUserData.sort((a, b) {
        return (b['recipe']['likes']?.length ?? 0).compareTo(a['recipe']['likes']?.length ?? 0);
      });
    } else if (dropdownValue == 'Điểm đánh giá cao nhất') {
      recipesWithUserData.sort((a, b) {
        return b['avgRating'].compareTo(a['avgRating']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDropdown(),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recipesWithUserData.length,
                        itemBuilder: (context, index) {
                          final recipeWithUser = recipesWithUserData[index];
                          final recipe = recipeWithUser['recipe'];
                          final user = recipeWithUser['user'];
                          final isFavorite = recipeWithUser['isFavorite'];

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index + 1 == 1
                                      ? Colors.amber
                                      : index + 1 == 2
                                          ? Colors.grey
                                          : Colors.brown,
                                ),
                                child: Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                width: 30,
                                height: 30,
                              ),
                              SizedBox(width: 10),
                              Container(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ItemRecipe(
                                      ontap: () {},
                                      name: recipe['namerecipe'],
                                      star: recipeWithUser['avgRating'].toStringAsFixed(1),
                                      favorite: (recipe['likes']?.length ?? 0).toString(),
                                      avatar: user['avatar'],
                                      fullname: user['fullname'],
                                      image: recipe['image'],
                                      isFavorite: isFavorite,
                                      onFavoritePressed: () =>
              
                                          FavoriteService().toggleFavorite(context, recipe['recipeId'], recipe['userID'], ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: mainColor, size: 20),
          style: TextStyle(color: mainColor, fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
              _fetchRecipes();
            });
          },
          items: <String>['Lượt thích cao nhất', 'Điểm đánh giá cao nhất']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/screens/home_screen/widgets/item_user.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/service/follow_service.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/rate_service.dart';
import 'package:recipe_app/service/user_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class ProposeScreen extends StatefulWidget {
  const ProposeScreen({super.key});

  @override
  State<ProposeScreen> createState() => _ProposeScreenState();
}

class _ProposeScreenState extends State<ProposeScreen> {
  String selectedIngredient = '';

  List<Map<String, dynamic>> cookingMethods = [];

  List<Map<String, dynamic>> ingredients = [];
  Future<void> fetchIngredients() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ingredients')
          .orderBy('createAt', descending: true)
          .get();

      setState(() {
        ingredients = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Thêm id vào map
          return data;
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching ingredients: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Lấy theo nguyên liệu
  List<Map<String, dynamic>> search = [];
  Future<List<Map<String, dynamic>>> fetchSearchRecipeData(
      String selectedIngredient) async {
    List<Map<String, dynamic>> recipeResults = [];

    try {
      QuerySnapshot recipeSnapshot =
          await FirebaseFirestore.instance.collection('recipes').where('status', isEqualTo: 'Đã được phê duyệt').get();
      var filteredDocs = recipeSnapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['hidden'] == false;
      }).toList();

      for (var doc in filteredDocs) {
        var recipeData = doc.data() as Map<String, dynamic>;
        var recipeId = doc.id;

        bool ingredientMatch = false;

        if (recipeData['ingredients'] != null &&
            recipeData['ingredients'] is List) {
          ingredientMatch = (recipeData['ingredients'] as List).any(
              (recipeIngredient) => recipeIngredient
                  .toString()
                  .toLowerCase()
                  .contains(selectedIngredient.toLowerCase()));
        }

        if (ingredientMatch) {
          var userId = recipeData['userID'];
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          var userData = userDoc.data();

          if (userData != null) {
            recipeData['recipeId'] = recipeId;
            bool isFavorite = await FavoriteService().isRecipeFavorite(recipeId,);

            recipeResults.add({
              'recipe': recipeData,
              'user': userData,
              'isFavorite': isFavorite,
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching recipe data: $e');
    }

    return recipeResults;
  }

  String selectedValue = 'Mới cập nhật';

  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> allRecipesWithUserData = [];
  bool isLoading = true;

  bool test = false;

  bool loadingRecipe = true;

  int currentPage = 1;
  int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchIngredients();
    _fetchRecipes();
    fetchCookingMethods();
  }

  

  // Get all user with id
  Future<List<Map<String, dynamic>>> fetchAllUsersWithId() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('followers', descending: true)
        .limit(10)
        .get();

    List<Map<String, dynamic>> users = querySnapshot.docs
        .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        })
        .where((user) => user['id'] != currentUser?.uid)
        .toList();

    return users;
  }

  Future<List<String>> fetchFollowedUsers() async {
    if (currentUser == null) {
      return [];
    }

    String currentUserId = currentUser!.uid;
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    List<dynamic> followedUsers = docSnapshot['followings'] ?? [];
    print(followedUsers);
    return List<String>.from(followedUsers);
  }
  
  // Danh sách công thức
  Future<void> _fetchRecipes() async {
    setState(() {
      test = true;
    });

    Query query = FirebaseFirestore.instance.collection('recipes');

    query = query.where('status', isEqualTo: 'Đã được phê duyệt');

    final QuerySnapshot recipeSnapshot = await query.get();

    var filteredDocs = recipeSnapshot.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['hidden'] == false;
    }).toList();

    allRecipesWithUserData = [];

    for (var recipeDoc in filteredDocs) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id;

      var userId = recipeData['userID'];

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userDoc.data();

      if (userData != null) {
        recipeData['recipeId'] = recipeId;

        bool isFavorite = await FavoriteService().isRecipeFavorite(recipeId,);
        
        var ratingData = await RateService().fetchAverageRating(recipeId, currentUser!.uid);

        allRecipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
          'isFavorite': isFavorite,
          'avgRating': ratingData['avgRating'],
          'ratingCount': ratingData['ratingCount'],
        });
      }
    }

    // Sắp xếp dữ liệu
    if (selectedValue == 'Mới cập nhật') {
      allRecipesWithUserData.sort((a, b) => 
        (b['recipe']['updateAt'] as Timestamp).compareTo(a['recipe']['updateAt'] as Timestamp));
    } else if (selectedValue == 'Nhiều tim nhất') {
      allRecipesWithUserData.sort((a, b) {
        return (b['recipe']['likes']?.length ?? 0).compareTo(a['recipe']['likes']?.length ?? 0);
      });
    } else if (selectedValue == 'Điểm cao nhất') {
      allRecipesWithUserData.sort((a, b) {
        return b['avgRating'].compareTo(a['avgRating']);
      });
    }

    setState(() {
      test = false;
      currentPage = 1;
    });
  }

  void _navigateToRecipeDetail(
    String recipeID,
    String userId,
  ) {
    print('Click');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailReCipe(recipeId: recipeID, userId: userId),
      ),
    );
  }

  // Cooking method
  bool loadingMedthod = false;

  Future<void> fetchCookingMethods() async {
    setState(() {
      loadingMedthod = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('cookingmethods')
          .orderBy('createAt', descending: true)
          .get();

      setState(() {
        cookingMethods = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add id to map
          return data;
        }).toList();
        loadingMedthod = false;
      });
    } catch (e) {
      print('Error fetching cooking methods: $e');
      setState(() {
        loadingMedthod = false;
      });
    }
  }

  List<Map<String, dynamic>> getCurrentPageRecipes() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > allRecipesWithUserData.length) {
      endIndex = allRecipesWithUserData.length;
    }
    return allRecipesWithUserData.sublist(startIndex, endIndex);
  }

  int get totalPages => (allRecipesWithUserData.length / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          StatefulBuilder(builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Text('Bạn đang có những nguyên liệu gì?'),
                    Text('Chọn 1-2 nguyên liệu'),
                    SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: ingredients.map((ingredient) {
                            bool isSelected =
                                selectedIngredient == ingredient['keysearch'];
                            return GestureDetector(
                              onTap: () async {
                                if (isSelected) {
                                  setState(() => selectedIngredient = '');
                                } else {
                                  setState(() {
                                    selectedIngredient =
                                        ingredient['keysearch'];
                                    loadingRecipe = true;
                                  });

                                  try {
                                    List<Map<String, dynamic>> results =
                                        await fetchSearchRecipeData(
                                            selectedIngredient);
                                    setState(() {
                                      search = results;
                                    });
                                  } catch (e) {
                                    print('Error in onTap: $e');
                                    // Handle error (e.g., show a snackbar to the user)
                                  } finally {
                                    setState(() => loadingRecipe = false);
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      ingredient['image'] ?? '',
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.error);
                                      },
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      ingredient['name'] ?? '',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (selectedIngredient.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Danh sách món'),
      SizedBox(height: 10),
      loadingRecipe
          ? Center(child: CircularProgressIndicator())
          : search.isEmpty
              ? Text('Không tìm thấy công thức nào.')
              : Container(
                  height: 142,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: search.length + 1, // Tăng itemCount lên 1
                    itemBuilder: (context, index) {
                      if (index < search.length) {
                        final recipeWithUser = search[index];
                        final recipe = recipeWithUser['recipe'];
                        final user = recipeWithUser['user'];
                        final isFavorite = recipeWithUser['isFavorite'];

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ItemRecipe(
                            ontap: () {
                              _navigateToRecipeDetail(
                                  recipe['recipeId'], recipe['userID']);
                            },
                            name: recipe['namerecipe'] ?? 'Không có tiêu đề',
                            star: (recipe['star'] ?? 0).toString(),
                            favorite:
                                (recipe['likes'] ?? []).length.toString(),
                            avatar: user['avatar'] ?? '',
                            fullname: user['fullname'] ?? 'Không rõ tên',
                            image: recipe['image'] ?? '',
                            isFavorite: isFavorite,
                            onFavoritePressed: () {
                              FavoriteService().toggleFavorite(context,
                                  recipe['recipeId'], recipe['userID'], );
                            },
                          ),
                        );
                      } else {
                        // Mũi tên cuối cùng
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchScreen(
                                    initialSearchTerm: selectedIngredient,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text('Xem thêm'),
                                    Icon(Icons.arrow_forward,
                                        color: Colors.black),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
                    if (selectedIngredient.isEmpty)
                      Container(
                        height: 300,
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 150,
                              child: Image.asset('assets/logo_noback.png'),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'Chọn một nguyên liệu',
                              style: TextStyle(fontSize: 25),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: 200,
                              child: Text(
                                'Chọn 1 đến 2 nguyên liệu để tìm ý tưởng cho món ăn',
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ),
            );
          }),
          SizedBox(
            height: 10,
          ),
          Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Phương pháp nấu'),
                SizedBox(height: 5,),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cookingMethods.length,
                    itemBuilder: (context, index) {
                      final cookingMethod = cookingMethods[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(initialSearchTerm: cookingMethod['keysearch']),
                            ),
                          );
                        },
                        child: Card(
                          color: cardBack,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipOval(
                                  child: Image.network(
                                    cookingMethod['image'] ?? '',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.error);
                                    },
                                  ),
                                ),
                                SizedBox(height: 5,),
                                Text(cookingMethod['name'] ?? 'No name')
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
          SizedBox(
            height: 10,
          ),
          FutureBuilder<List<String>>(
            future: fetchFollowedUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              List<String> followedUsers = snapshot.data ?? [];
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchAllUsersWithId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  List<Map<String, dynamic>> users = snapshot.data ?? [];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Người dùng nổi bật'),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                bool isFollowing = false;
                                if (currentUser != null) {
                                  isFollowing =
                                      followedUsers.contains(user['id']);
                                }
                                return ItemUser(
                                  ontap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ProfileUser(userId: user['id']),
                                      ),
                                    );
                                  },
                                  avatar: (user['avatar'] != null &&
                                          user['avatar'].isNotEmpty)
                                      ? user['avatar']
                                      : 'https://firebasestorage.googleapis.com/v0/b/recipe-app-5a80e.appspot.com/o/profile_images%2F1719150232272?alt=media&token=ea875488-b4bd-43f1-b858-d6eba92e982a',
                                  fullname: user['fullname'] ?? 'N/A',
                                  username: user['username'] ?? 'N/A',
                                  recipe: (user['recipes'] as List)
                                      .length
                                      .toString(),
                                  follow: isFollowing,
                                  clickFollow: () async {
                                    if (currentUser != null) {
                                      await FollowService().toggleFollow(currentUser!.uid, user['id']  );
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text('Bạn chưa đăng nhập'),
                                            content: Text(
                                                'Vui lòng đăng nhập để tiếp tục.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const SignInScreen()),
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
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(
            height: 10,
          ),
          StatefulBuilder(builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danh sách công thức'),
                      DropdownButton<String>(
                        value: selectedValue,
                        items: <String>[
                          'Mới cập nhật',
                          'Nhiều tim nhất',
                          'Điểm cao nhất'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedValue = newValue!;
                            test = true;
                          });
                          await _fetchRecipes();
                        },
                      ),
                    ],
                  ),
                  test
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: getCurrentPageRecipes().length,
                              itemBuilder: (context, index) {
                                final recipeWithUser = getCurrentPageRecipes()[index];
                                final recipe = recipeWithUser['recipe'];
                                final user = recipeWithUser['user'];
                                bool isFavorite = recipeWithUser['isFavorite'];

                                return Container(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: ItemRecipe(
                                        ontap: () {
                                          _navigateToRecipeDetail(recipe['recipeId'], recipe['userID']);
                                        },
                                        name: recipe['namerecipe'] ?? 'Không có tiêu đề',
                                        star: recipeWithUser['avgRating'].toStringAsFixed(1),
                                        favorite: (recipe['likes']?.length ?? 0).toString(),
                                        avatar: user['avatar'] ?? 'assets/food_intro.jpg',
                                        fullname: user['fullname'] ?? 'Không rõ tên',
                                        image: recipe['image'] ?? 'https://candangstudio.com/wp-content/uploads/2022/04/studio-session-040_51065362217_o.jpg',
                                        isFavorite: isFavorite,
                                        onFavoritePressed: () => FavoriteService().toggleFavorite(context, recipe['recipeId'], recipe['userID'],),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.chevron_left),
                                  onPressed: currentPage > 1
                                      ? () {
                                          setState(() {
                                            currentPage--;
                                          });
                                        }
                                      : null,
                                ),
                                Text('Trang $currentPage / $totalPages'),
                                IconButton(
                                  icon: Icon(Icons.chevron_right),
                                  onPressed: currentPage < totalPages
                                      ? () {
                                          setState(() {
                                            currentPage++;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:recipe_app/screens/ranking_screen/recipe_ranking.dart';
import 'package:recipe_app/screens/ranking_screen/user_ranking.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String dropdownValue = 'Option 1';

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
        title: Text('Khám phá'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    width: 1,
                    color: Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8.0),
                    Text('Tìm kiếm ...'),
                  ],
                ),
              ),
            ),
          ),
          TabBar(
             dividerColor: Colors.transparent,
            controller: _tabController,
            tabs: [
              Tab(text: 'Xếp hạng công thức'),
              Tab(text: 'Xếp hạng người dùng'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RecipeRanking(),
                UserRanking(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: RankingScreen(),
  ));
}

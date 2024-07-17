
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String? id;
  final String namerecipe;
  final String description;
  final String ration;
  final String time;
  final List<String> ingredients;
  final List<String> steps;
  final String image;
  final String level;
  final List<String> likes;
  final List<dynamic> rates;
  final List<dynamic> comments;
  final String status;
  final String userID;
  final String urlYoutube;
  final Timestamp? createAt;
  final Timestamp? updateAt;
  final bool hidden;
  final bool official;

  RecipeModel({
    this.id,
    required this.namerecipe,
    required this.description,
    required this.ration,
    required this.time,
    required this.ingredients,
    required this.steps,
    required this.image,
    required this.level ,
    this.likes = const [],
    this.rates = const [],
    this.comments = const [],
    this.status = 'Đợi phê duyệt',
    required this.userID,
    required this.urlYoutube,
    this.createAt,
    this.updateAt,
    this.hidden = false,
    this.official = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'namerecipe': namerecipe,
      'description': description,
      'ration': ration,
      'time': time,
      'ingredients': ingredients,
      'steps': steps,
      'image': image,
      'level': level,
      'likes': likes,
      'rates': rates,
      'comments': comments,
      'status': status,
      'userID': userID,
      'urlYoutube': urlYoutube,
      'createAt': createAt ?? FieldValue.serverTimestamp(),
      'updateAt': updateAt ?? FieldValue.serverTimestamp(),
      'hidden': hidden,
      'official': official,
    };
  }

  factory RecipeModel.fromMap(Map<String, dynamic> map, String id) {
    return RecipeModel(
      id: id,
      namerecipe: map['namerecipe'] ?? '',
      description: map['description'] ?? '',
      ration: map['ration'] ?? '',
      time: map['time'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      steps: List<String>.from(map['steps'] ?? []),
      image: map['image'] ?? '',
      level: map['level'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      rates: map['rates'] ?? [],
      comments: map['comments'] ?? [],
      status: map['status'] ?? 'Đợi phê duyệt',
      userID: map['userID'] ?? '',
      urlYoutube: map['urlYoutube'] ?? '',
      createAt: map['createAt']?.toDate(),
      updateAt: map['updateAt']?.toDate(),
      hidden: map['hidden'] ?? false,
      official: map['official'] ?? true,
    );
  }
}
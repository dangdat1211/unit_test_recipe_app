class UserModel {
  final String id;
  final String username;
  final String fullname;
  final String email;
  final String bio;
  final String avatar;
  final bool status;
  final DateTime createAt;
  final String updateAt;
  final String role;
  final List<String> favorites;
  final List<String> followers;
  final List<String> followings;
  final List<String> recipes;
  final String fcm;

  UserModel({
    required this.id,
    required this.username,
    required this.fullname,
    required this.email,
    this.bio = '',
    this.avatar = 'https://firebasestorage.googleapis.com/v0/b/recipe-app-5a80e.appspot.com/o/profile_images%2F1719150232272?alt=media&token=ea875488-b4bd-43f1-b858-d6eba92e982a',
    this.status = true,
    required this.createAt,
    this.updateAt = '',
    this.role = '',
    this.favorites = const [],
    this.followers = const [],
    this.followings = const [],
    this.recipes = const [],
    this.fcm = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'fullname': fullname,
      'email': email,
      'bio': bio,
      'avatar': avatar,
      'status': status,
      'createAt': createAt,
      'updateAt': updateAt,
      'role': role,
      'favorites': favorites,
      'followers': followers,
      'followings': followings,
      'recipes': recipes,
      'FCM': fcm,
    };
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;


class NotificationService {

  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseFirestore? firestore
  }) : 
      _firestore = firestore ?? FirebaseFirestore.instance;


  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<String> getAccessToken() async {
    await dotenv.load();
    print(dotenv.env['SERVICE_ACCOUNT_TYPE']);
    final Map<String, dynamic> serviceAccountJson = {
      "type": dotenv.env['SERVICE_ACCOUNT_TYPE'],
      "project_id": dotenv.env['PROJECT_ID'],
      "private_key_id": dotenv.env['PRIVATE_KEY_ID'],
      "private_key": dotenv.env['PRIVATE_KEY'],
      "client_email": dotenv.env['CLIENT_EMAIL'],
      "client_id": dotenv.env['CLIENT_ID'],
      "auth_uri": dotenv.env['AUTH_URI'],
      "token_uri": dotenv.env['TOKEN_URI'],
      "auth_provider_x509_cert_url": dotenv.env['AUTH_PROVIDER_X509_CERT_URL'],
      "client_x509_cert_url": dotenv.env['CLIENT_X509_CERT_URL'],
      "universe_domain": dotenv.env['UNIVERSE_DOMAIN']
    };

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging"
    ];

    try {
      final credentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      rethrow;
    }
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<String?> getDeviceToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  void isTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      // Handle token refresh logic
      print('Token refreshed: $newToken');
    });
  }

  void initLocalNotification(BuildContext context) async {
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = DarwinInitializationSettings();

    var initSetting = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSetting,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  static void onNotificationTap(NotificationResponse notificationResponse) {
    final payloadData = notificationResponse.payload != null
        ? json.decode(notificationResponse.payload!) as Map<String, dynamic>
        : null;

    if (payloadData != null) {
      final screen = payloadData['screen'];
      final userId = payloadData['userId'];
      final recipeId = payloadData['recipeId'];

      // if (screen == 'recipe') {
      //   navigatorKey.currentState?.push(
      //     MaterialPageRoute(
      //         builder: (context) => DetailReCipe(
      //               recipeId: recipeId,
      //               userId: userId,
      //             )),
      //   );
      // } else if (screen == 'comment') {
      //   navigatorKey.currentState?.push(
      //     MaterialPageRoute(
      //         builder: (context) => CommentScreen(
      //               recipeId: recipeId,
      //               userId: userId,
      //             )),
      //   );
      // } else if (screen == 'user') {
      //   navigatorKey.currentState?.push(
      //     MaterialPageRoute(
      //         builder: (context) => ProfileUser(userId: userId)),
      //   );
      // }
    } else {
      print('Khong co gi');
    }
  }

  Future<void> firebaseInit(BuildContext context) async {
    FirebaseMessaging.onMessage.listen((message) {
      if (Platform.isAndroid) {
        initLocalNotification(context);
        showNotification(message);
      } else {
        // Xử lý trực tiếp cho iOS
        String payload = json.encode(message.data);
        onNotificationTap(NotificationResponse(
          payload: payload,
          notificationResponseType:
              NotificationResponseType.selectedNotification,
        ));
      }
      handleNotification(context, message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotification(context, message);
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    String payload = json.encode(message.data);
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'High Importance Notifications',
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
      payload: payload,
    );
  }

   Future<void> sendNotification(
      String fcmToken, String title, String body,
      {Map<String, dynamic>? data}) async {
    try {
      final String serverKey = await getAccessToken();
      final String endpoint =
          'https://fcm.googleapis.com/v1/projects/recipe-app-5a80e/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          if (data != null) 'data': data,
        }
      };

      final http.Response response = await http.post(Uri.parse(endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $serverKey'
          },
          body: jsonEncode(message));

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void handleNotification(BuildContext context, RemoteMessage message) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => NotifyScreen()),
    // );
  }

  Future<void> createNotification({
    required String content,
    required String fromUser,
    required String userId,
    required String recipeId,
    required String screen,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'content': content,
        'createAt': FieldValue.serverTimestamp(),
        'fromUser': fromUser,
        'isRead': false,
        'recipeId': recipeId,
        'screen': screen,
        'userId': userId,
      });
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
      throw e;
    }
  }
}

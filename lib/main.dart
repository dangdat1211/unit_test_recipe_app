import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recipe_app/firebase_options.dart';
import 'package:recipe_app/helpers/local_storage_helper.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/notification_service.dart';

// Global instance of NotificationService
final NotificationService notificationService = NotificationService();
final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

void handleNotificationOpen(RemoteMessage message, BuildContext context) {
  print('Notification opened: ${message.data}');
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SignInScreen()),
  );
}

Future<void> main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await LocalStorageHelper.initLocalStorageHelper();

  notificationService.requestNotificationPermission();
  notificationService.getDeviceToken().then((value) {
    print('Token FCM : $value');
  });
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    
    // Xử lý khi app đang chạy ở background và người dùng bấm vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationOpen(message, context);
    });

    // Xử lý khi app đã tắt hoàn toàn và được mở lại bởi thông báo
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        handleNotificationOpen(message, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
            background: Colors.grey.shade100,
            primary: Color(0xFFFF7622),
            outline: Colors.grey),
        scaffoldBackgroundColor: Colors.grey[100],
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          color: Colors.grey[100],
        ),
      ),
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (BuildContext context) {
          print('Đến đây thôi');
          notificationService.firebaseInit(context);
          print('Qua đây rồi');

          return Scaffold(
            body: Center(child: SplashScreen()),
          );
        },
      ),
    );
  }
}
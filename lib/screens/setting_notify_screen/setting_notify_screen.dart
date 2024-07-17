import 'package:flutter/material.dart';
import 'package:recipe_app/screens/user_screen/widgets/ui_container.dart';
import 'package:recipe_app/service/notification_service.dart';

class SettingNotifyScreen extends StatefulWidget {
  const SettingNotifyScreen({super.key});

  @override
  State<SettingNotifyScreen> createState() => _SettingNotifyScreenState();
}

class _SettingNotifyScreenState extends State<SettingNotifyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt thông báo'),
      ),
      body: Center(
        child: UIContainer(
            ontap: () async {
              String? notify = await NotificationService().getDeviceToken();

              NotificationService().sendNotification(
                  notify!, "Check", "Nội dung thông báo",
                  data: {'screen': 'user', 'userId': 'L7QEDUSiRhZSK0TWt2WSg0sci9U2'});
            },
            color: Colors.red,
            title: 'Gửi thông báo'),
      ),
    );
  }
}

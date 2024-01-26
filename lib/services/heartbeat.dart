import 'dart:async';

import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';

class HeartbeatManager {
  static HeartbeatManager? _instance;
  late Timer _heartbeatTimer;

  HeartbeatManager._internal();

  factory HeartbeatManager() {
    if (_instance == null) {
      _instance = HeartbeatManager._internal();
    }
    return _instance!;
  }

  void startHeartbeat(String userName) {
    const Duration heartbeatInterval = Duration(seconds: 5);

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) async {
      // Perform the actions you want to execute in the heartbeat
      print("Heartbeat for user $userName");

      // For example, you can update the user status here
      String? myUserIdNumber = await SharedPreference().getUserID();
      await DatabaseMethods().updateUserStatus(myUserIdNumber!, "Online");
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer.cancel();
  }
}

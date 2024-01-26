import 'package:chatappdemo1/Pages/Login.dart';
import 'package:chatappdemo1/Pages/homepage.dart';
import 'package:chatappdemo1/Pages/signUp.dart';
import 'package:chatappdemo1/services/auth.dart' as appAuth;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider.value(
      value: appAuth.AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider =
        Provider.of<appAuth.AuthProvider>(context, listen: false);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<User?>(
        future: authProvider.getCurrentUser(),
        builder: (context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasData && snapshot.data != null) {
              return Home();
            } else {
              return LoginPage();
            }
          }
        },
      ),
    );
  }
}

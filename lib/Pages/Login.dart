import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unnecessary_import
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:chatappdemo1/Pages/signUp.dart';
import 'package:chatappdemo1/Pages/forgotpass.dart';
import 'package:chatappdemo1/Pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //controllers
  //storing data here
  String userName = "", id = "", photo = "", email = "", password = "";

  //key for saving form data
  final _formkey = GlobalKey<FormState>();

  //login function here
  userLogin() async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      //the function from Database.dart
      QuerySnapshot querySnapshot =
          await DatabaseMethods().getUserbyEmail(email);

      userName = "${querySnapshot.docs[0]["Username"]}";
      photo = "${querySnapshot.docs[0]["Photo"]}";
      email = "${querySnapshot.docs[0]["Email"]}";
      id = querySnapshot.docs[0].id;

      //storing data
      await SharedPreference().setUserID(id);
      await SharedPreference().setUserEmail(email);
      await SharedPreference().setUserPhoto(photo);
      await SharedPreference().setUserName(userName);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } on FirebaseException catch (t) {
      if (t.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "No User Found with this E-mmail",
              style: TextStyle(fontFamily: "Montserrat-R", fontSize: 20),
            ),
          ),
        );
      } else if (t.code == 'wrong password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password is Incorrect, Please try again.",
              style: TextStyle(fontFamily: "Montserrat-R", fontSize: 20),
            ),
          ),
        );
      }
    }
  }

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TO DO redesign the app bar
      appBar: AppBar(
        title: const Text(
          'Welcome to Instachat',
          style: TextStyle(fontFamily: 'FuturaLight', fontSize: 30),
        ),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      //input field
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  //validator is here
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please Enter Your E-mail";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border:
                          OutlineInputBorder(borderSide: BorderSide(width: 1))),
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please Enter Your Password";
                    }
                    return null;
                  },
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(width: 1),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPass(),
                            ));
                      },
                      child: Text('Forgot Password?'),
                    ),
                  ],
                ),
                SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: () {
                    //auth here
                    if (_formkey.currentState!.validate()) {
                      setState(
                        () {
                          email = _emailController.text;
                          password = _passwordController.text;
                        },
                      );
                    }
                    userLogin();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white70),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'FuturaLight',
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the Sign Up page when the button is pressed
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => signUp()));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontFamily: 'FuturaLight',
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:chatappdemo1/Pages/homepage.dart';
import 'package:chatappdemo1/services/database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_string/random_string.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class signUp extends StatefulWidget {
  const signUp({super.key});

  @override
  State<signUp> createState() => _SignUpState();
}

class _SignUpState extends State<signUp> {
  String? randomID() {
    DateTime now = DateTime.now();

    String formattedDate = DateFormat('yyMMddkkmm').format(now);

    final String theUserID = math.Random().nextInt(10 + 90).toString();

    return (formattedDate + theUserID);
  }

  //field validiations here
  final _formkey = GlobalKey<FormState>();

  String userName = "", email = "", password = "", confirmPassword = "";
  //controllers for information retieval
  TextEditingController _emailController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  //registration function here
  registration() async {
    //username and password is checked
    // ignore: unnecessary_null_comparison
    if (password != null) {
      try {
        //waits for the result before proceeding with the operation
        // ignore: unused_local_variable
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        //generate id for user upon registration
        String id = randomID() as String;
        //maps the information to integrate it to firebase db
        Map<String, dynamic> userInformationMap = {
          "Username": _usernameController.text,
          "Email": _emailController.text,
          "Password": _passwordController.text,
          "Confirmed Password": _confirmPasswordController.text,
          "Photo":
              "https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg",
          "id": id,
          "Fullname": "",
        };
        //databasemthods is called here
        await DatabaseMethods().addUserDetails(userInformationMap, id);
        //call save info function here
        await SharedPreference().setUserID(id);
        await SharedPreference().setUserName(_usernameController.text);
        await SharedPreference().setUserEmail(_emailController.text);
        // TO DO implement photo function

        //display successful message with snackbar
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Registration was successful!",
              style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
            ),
          ),
        );
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(),
            ));
      }
      //eexception handling
      on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Weak Password, Enter a different password",
                style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
              ),
            ),
          );
        } else if (e.code == 'username-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Username Taken, Please Enter a Different Username!',
                style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
              ),
            ),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An Account Has Been Registered with this email!',
                style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
              ),
            ),
          );
        } else {
          //Firebase Authentication errors here
          print("Error: ${e.message}");
        }
      } catch (e) {
        //non-Firebase related errors
        print("Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appbar, TO DO, color to be changed
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Form(
            //form key here
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //enter username, Textformfield to capture information
                TextFormField(
                  controller: _usernameController,
                  //validates the username using validator
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is Required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                      labelText: 'Enter Username',
                      prefixIcon: Icon(Icons.person),
                      border:
                          OutlineInputBorder(borderSide: BorderSide(width: 1))),
                ),
                SizedBox(
                  height: 16,
                ),
                //enter email,
                TextFormField(
                  controller: _emailController,
                  //validates the email using validator
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'An E-mail is Required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter E-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                //enter password
                TextFormField(
                  controller: _passwordController,
                  //hides password during input
                  obscureText: true,
                  //validates the password using validator
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is Required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Enter Password',
                    prefixIcon: Icon(Icons.password_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                //confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  //validates the confirmation of the password
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Confirm Your Password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                //the sign up confirm button
                ElevatedButton(
                  onPressed: () {
                    //checks if the form is complete
                    if (_formkey.currentState!.validate()) {
                      //sets the informations
                      setState(
                        () {
                          userName = _usernameController.text;
                          email = _emailController.text;
                          password = _passwordController.text;
                        },
                      );
                    }
                    //registers the user if the information submitted is true
                    registration();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: EdgeInsets.symmetric(horizontal: 50)),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontFamily: 'FuturaLight',
                        fontSize: 18.0,
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

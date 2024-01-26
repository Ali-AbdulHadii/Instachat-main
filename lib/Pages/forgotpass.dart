import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  //
  String email = "";
  final _formkey = GlobalKey<FormState>();

  TextEditingController _emailController = TextEditingController();

  passwordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          "An Email has been sent to your inbox.",
          style: TextStyle(fontFamily: "Montserrat-R", fontSize: 20),
        )),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
            "User asscoiated with this Email has not been found.",
            style: TextStyle(fontFamily: "Montserrat-R", fontSize: 20),
          )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //reset password page
      appBar: AppBar(
        title: const Text(
          'Reset Your Password',
          style: TextStyle(fontFamily: 'FuturaLight', fontSize: 24),
        ),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          //form key here
          key: _formkey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //input for email
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter Your Email";
                  }
                  return null;
                },
                decoration: InputDecoration(
                    labelText: 'Your Email Address',
                    border:
                        OutlineInputBorder(borderSide: BorderSide(width: 1))),
              ),
              //send reset password email
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  //handles forgetting password logic is here
                  if (_formkey.currentState!.validate()) {
                    setState(
                      () {
                        email = _emailController.text;
                      },
                    );
                  }
                  passwordReset();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text(
                  'Send',
                  style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'FuturaLight',
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

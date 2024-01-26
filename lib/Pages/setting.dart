import 'dart:io';
import 'package:chatappdemo1/Pages/Login.dart';
import 'package:chatappdemo1/Pages/signUp.dart';
import 'package:chatappdemo1/services/auth.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:chatappdemo1/services/database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class settings extends StatefulWidget {
  //const settings({super.key});
  String? userName, profileURL, fullname;
  settings({
    super.key,
    required this.userName,
    required this.profileURL,
    required this.fullname,
  });

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
  String? myId;
  //store the selected image
  File? _image;
  Key circleAvatarKey = GlobalKey();
  TextEditingController _nameController = TextEditingController();
  //compress function
  //choosing the image and uploading it
  Future _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Show a Snackbar to indicate that the image has been uploaded
      final snackBar = SnackBar(
        content: Text('Image uploaded'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      //upload sleteced image to firebase
      String? profilePhotoURL =
          await DatabaseMethods().uploadUserProfilePhoto(_image!);
      await SharedPreference().setUserPhoto(profilePhotoURL!);
      //null check
      // ignore: unnecessary_null_comparison
      if (profilePhotoURL != null) {
        //update the widget's profileURL with the new download URL
        if (mounted) {
          setState(() {
            widget.profileURL = profilePhotoURL;
          });
        }
        //force a rebuild of the circleavatar by creating a new Key
        Key newKey = Key(profilePhotoURL);
        circleAvatarKey = newKey;
        //show snackbar to indicate the image has been uploaded
        final uploadSnackBar = SnackBar(
          content: Text("Image Uploaded"),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(uploadSnackBar);
      } else {
        //hnadle case
        final uploadErrorsnackBar = SnackBar(
          content: Text("Failed to upload image"),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(uploadErrorsnackBar);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    //load user's name from sharepref
    loadFullName();
    getSharedPref();
  }

  //load user data from shared preferences
  void onLoad() async {
    //gets local data
    getSharedPref();
  }

  getSharedPref() async {
    // ignore: unnecessary_cast
    myId = await SharedPreference().getUserID() as String?;
  }

  //function to load the user's full name from sharedpref
  void loadFullName() async {
    String? storedFullName = await SharedPreference().getDisplayName();
    if (storedFullName != null && mounted) {
      setState(() {
        widget.fullname = storedFullName;
      });
    }
  }

  Future<void> _editName() async {
    String? newName = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Name"),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: 'Enter your new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, _nameController.text);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null) {
      //update the users name and save to database
      await SharedPreference().setDisplayName(newName);
      await DatabaseMethods().updateDisplayName(myId!, newName);
      // For now, we'll just update the widget's state
      setState(() {
        widget.fullname = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Montserrat-R', fontSize: 20),
        ),
        backgroundColor: Colors.amber.shade600,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(top: 30),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: widget.profileURL != null &&
                        widget.profileURL!.isNotEmpty
                    ? NetworkImage(widget.profileURL!)
                    : NetworkImage(
                        "https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg"),
              ),
            ),
            SizedBox(height: 10),
            Container(
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Edit"),
                        content: Column(
                          children: [
                            ListTile(
                              title: Text('Camera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              title: Text('Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
                child: Text(
                  'Edit',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: "Montserrat-R",
                      fontSize: 14,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ),
            SizedBox(height: 30),
            Column(
              children: [
                Container(
                  child: Text(
                    "DISPLAY NAME",
                    style: TextStyle(fontFamily: "Montserrat-R", fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5),
            Container(
              height: 30,
              width: 300,
              decoration: BoxDecoration(
                  color: Colors.amber, borderRadius: BorderRadius.circular(5)),
              child: InkWell(
                onTap: () {
                  _editName();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Text(
                        widget.fullname ?? '',
                        style:
                            TextStyle(fontFamily: "Montserrat-R", fontSize: 16),
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Container(
              child: ElevatedButton(
                child: Text(
                  'Sign Out',
                  style: TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
                ),
                onPressed: () async {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

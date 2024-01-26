import 'package:chatappdemo1/Pages/homepage.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:flutter/material.dart';
import 'package:chatappdemo1/services/database.dart';

class AddFriend extends StatefulWidget {
  const AddFriend({Key? key});

  @override
  State<AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<AddFriend> {
  TextEditingController _friendUsername = TextEditingController();
  List<String> friendRequests = [];

  @override
  void initState() {
    super.initState();
    updateFriendRequestsList();
  }

  String friendUsername = "";
  String senderId = "";
  String recipientId = "";

  Future<void> addFriend() async {
    //get the entered friend's username
    String friendUsername = _friendUsername.text;

    if (friendUsername.isEmpty) {
      //show a snack bar if the username is empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Enter a valid username"),
      ));
    } else {
      try {
        //get sender and recipient IDs
        senderId = await SharedPreference().getUserID() as String;
        recipientId = await DatabaseMethods()
            .getUserIdByUsername(friendUsername) as String;

        //check if friend request already sent
        bool requestExists = await DatabaseMethods()
            .checkFriendRequestExist(senderId, recipientId);

        if (requestExists) {
          //check if the friend request is accepted
          String requestStatus = await DatabaseMethods()
              .checkFriendRequestStatus(senderId, recipientId);

          if (requestStatus == "accepted") {
            //show a snack bar if the request has already been accepted
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Friend request has already been accepted"),
            ));
            updateFriendRequestsList();
          } else if (requestStatus == "pending") {
            //await DatabaseMethods().sendFriendRequest(senderId, recipientId);
            //if the request has already been accepted
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Friend request is pending"),
            ));
            updateFriendRequestsList();
          } else if (requestExists == "rejected") {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Friend request is rejected"),
            ));
            updateFriendRequestsList();
          }
        } else {
          //send friend request and update the list
          print("No existing friend request, sending new request");
          await DatabaseMethods().sendFriendRequest(senderId, recipientId);
          updateFriendRequestsList();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Friend request sent successfully")),
          );
        }
      } catch (t) {
        //if username not found
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Username not found"),
        ));
      }
    }
  }

  Future<void> updateFriendRequestsList() async {
    try {
      //fetch friend requests and update the list
      List<String> newFriendRequests =
          await DatabaseMethods().getFriendRequests();
      setState(() {
        friendRequests = newFriendRequests;
      });
    } catch (e) {
      print("error fetching friend requests: $e");
    }
  }

  void acceptFriendRequest(String friendUsername) async {
    try {
      //get sender and friend IDs
      // ignore: unnecessary_cast
      String? senderId = await SharedPreference().getUserID() as String?;
      // ignore: unnecessary_cast
      String? friendId = await DatabaseMethods()
          .getUserIdByUsername(friendUsername) as String?;

      if (senderId == null || friendId == null) {
        //show a snack bar if unable to get user ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get user ID")),
        );
        return;
      }

      //accept friend request and update local friends list
      await DatabaseMethods().acceptFriendRequest(friendId, senderId);
      Set<String> localFriends = await (SharedPreference().getFriendsList());
      localFriends.add(friendUsername);
      await SharedPreference().setFriendsList(localFriends.toList());
      updateFriendRequestsList();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend request accepted")),
      );
      //refresh the Home page
      //Navigator.pop(context); //close the AddFriend page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error accepting friend request: $e")),
      );
    }
  }

  void rejectFriendRequest(String friendUsername) async {
    try {
      //get sender and friend IDs
      String senderId = await SharedPreference().getUserID() as String;
      String friendId =
          await DatabaseMethods().getUserIdByUsername(friendUsername) as String;

      //logic to remove or update the friend request status
      await DatabaseMethods().rejectFriendRequest(friendId, senderId);
      //update the friend requests list after rejecting
      updateFriendRequestsList();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Friend request rejected"),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("error rejecting friend request: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber,
              Colors.orange,
              Colors.red,
              Colors.purple,
              Colors.deepPurple.shade700
            ],
          ),
        ),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.2,
              padding: EdgeInsets.only(left: 20, right: 20, top: 100),
              child: Column(
                children: [
                  SizedBox(height: 18),
                  Text(
                    "Enter Friend's Username",
                    style: TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: TextField(
                      controller: _friendUsername,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(width: 1)),
                        contentPadding: EdgeInsets.all(10),
                        hintText: 'Username',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      addFriend();
                    },
                    child: Text(
                      "Send Friend Request",
                      style:
                          TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 40),
                  Container(
                    child: Text(
                      "Friend Requests",
                      style:
                          TextStyle(fontFamily: "Montserrat-R", fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: friendRequests.length,
                    itemBuilder: (context, index) {
                      String friendUsername = friendRequests[index];
                      return ListTile(
                        title: Text(friendRequests[index]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                acceptFriendRequest(friendUsername);
                              },
                              icon: Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () {
                                rejectFriendRequest(friendUsername);
                              },
                              icon: Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            Container(
              //top bar for returning, profile picture, and username
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: 60, left: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => Home()));
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width / 4),
                  Text(
                    "Add Friends",
                    style: TextStyle(
                      fontFamily: "Montserrat-R",
                      fontSize: 20,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

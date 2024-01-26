import 'dart:async';
import 'package:chatappdemo1/services/database.dart';
import 'package:chatappdemo1/services/heartbeat.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:chatappdemo1/Pages/homepage.dart';

// ignore: must_be_immutable
class ChatSection extends StatefulWidget {
  String? userName, profileURL, displayName;
  ChatSection({
    required this.userName,
    required this.profileURL,
    required this.displayName,
  });

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection> {
  //controller
  TextEditingController _messageController = TextEditingController();
  //storing info for the current user
  String? myUsername, myProfilePhoto, myEmail, messageId, chatroomId, myUserId;
  //storing info for the other user
  String? otherUserId;
  //stream message
  Stream? messageStream;

  //friends userId, stream friend status
  String? friendUserId, friendStatus = "";

  //chatroomid
  getChatIdbyUserId(String a, String b) {
    int parseA = int.parse(a);
    int parseB = int.parse(b);
    if (parseA > parseB) {
      print("parseA > parseB");
      return "$parseA\_$parseB";
    } else {
      print("parseA <= parseB");
      return "$parseB\_$parseA";
    }
  }

  //randomID generator
  String? randomID() {
    DateTime now = DateTime.now();

    String formattedDate = DateFormat('yyMMddkkmm').format(now);

    final String messageId = math.Random().nextInt(10 + 90).toString();
    final DateTime messageTimestamp = DateTime.now();
    String messageDateFormat = DateFormat('h:mma').format(messageTimestamp);
    return (formattedDate + messageId + messageDateFormat);
  }

  Widget chatMessageTile(String message, bool SentByMe) {
    return Row(
      mainAxisAlignment:
          SentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomRight:
                      SentByMe ? Radius.circular(0) : Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft:
                      SentByMe ? Radius.circular(20) : Radius.circular(0),
                ),
                color: SentByMe ? Colors.amber : Colors.orange),
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "Montserrat-R",
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget chatMessage() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  padding: EdgeInsets.only(bottom: 90, top: 130),
                  itemCount: snapshot.data.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot docSnapshot = snapshot.data.docs[index];
                    return chatMessageTile(docSnapshot["message"],
                        myUsername == docSnapshot["sentBy"]);
                  })
              : Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  //get and set msgs
  getAndSetMessage() async {
    messageStream = await DatabaseMethods().getChatroomMessages(chatroomId);
    //await DatabaseMethods().resetUnreadCounter(widget.userName!);
    //setstate
    if (mounted) {
      setState(() {});
    }
  }

  //function to send the message
  addMessage(bool sendIconPressed) {
    if (_messageController.text != "") {
      String message = _messageController.text;
      _messageController.text = "";

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('h:mma').format(now);
      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sentBy": myUsername,
        "ts": formattedDate,
        "time": FieldValue.serverTimestamp(),
        "isRead": false,
      };
      //generate randomID for msgs
      messageId = randomID();
      //call addmessage function from databasemethods.dart
      print(chatroomId);
      DatabaseMethods()
          .addMessage(chatroomId!, messageId!, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": formattedDate,
          "time": FieldValue.serverTimestamp(),
          "lastMessageSendBy": myUsername,
          "unreadCounter_$myUserId": FieldValue.increment(1),
        };
        DatabaseMethods()
            .updateLastMessageSent(chatroomId!, lastMessageInfoMap);
        if (sendIconPressed) {
          messageId = null;
        }
      });
    }
  }

  getSharePrefs() async {
    myUsername = await SharedPreference().getUserName();
    myProfilePhoto = await SharedPreference().getUserPhoto();
    myEmail = await SharedPreference().getUserEmail();
    myUserId = await SharedPreference().getUserID();
    otherUserId = await DatabaseMethods().getUserIdByUsername(widget.userName!);
    chatroomId = getChatIdbyUserId(myUserId!, otherUserId!);
    print(otherUserId);
    friendStatus = await DatabaseMethods().getUserStatus(otherUserId!);
  }

  //load user data from shared preferences
  void onLoad() async {
    try {
      await getSharePrefs();
      await getAndSetMessage();
      setState(() {});
    } catch (e) {
      print("error in onLoad: $e");
    }
  }

  String? friendProfilePhotoURL;

  //function to get friend's photo URL
  Future<void> getFriendProfilePhoto() async {
    friendProfilePhotoURL =
        await DatabaseMethods().getFriendPhotoURL(widget.userName!);
  }

  //function to check status and set status
  Future<bool> OtherUserStillOnline(userId) async {
    Timestamp? timestamp;

    timestamp = await DatabaseMethods().getUserLastUpdate(userId);
    if (timestamp != null) {
      // Convert Timestamp to DateTime
      DateTime lastUpdateDateTime = timestamp.toDate();
      //convert Timestamp to DateTime and then to String
      Duration difference = DateTime.now().difference(lastUpdateDateTime);

      if (difference.inSeconds >= 10) {
        return true;
      } else {
        return false;
      }
    } else {
      print("Error time stamp is $timestamp");
      return false;
    }
  }

  void CheckUserStatusAndSet() async {}

  Timer? timer;
  //function to periodically check user status
  void checkUserStatusPeriodically() {
    timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      bool isIdle = await OtherUserStillOnline(otherUserId);
      String? userStatus = await DatabaseMethods().getUserStatus(otherUserId!);
      print("user is  $userStatus");
      if (mounted) {
        if (isIdle && userStatus == 'Online') {
          print("User is $userStatus. Changing his status to offline.");
          await DatabaseMethods().offlineUserStatus(otherUserId!, "");
          setState(() {
            friendStatus = "";
          });
        } else if (isIdle && userStatus == "") {
          setState(() {
            friendStatus = "";
          });
        } else if (!isIdle && userStatus == "Online") {
          setState(() {
            friendStatus = "Online";
          });
        }
      } else {
        print("user is $userStatus");
        //todp
      }
    });
  }

  //init state
  @override
  void initState() {
    super.initState();
    onLoad();
    getFriendProfilePhoto();
    checkUserStatusPeriodically();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        //instachat main colors
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
        padding: EdgeInsets.only(top: 50.0),
        child: Stack(
          children: [
            Container(
              //main messages container
              margin: EdgeInsets.only(top: 60.0),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 1.12,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.amber,
                    Colors.orange,
                    Colors.red,
                    Colors.purple,
                    Colors.deepPurple.shade700
                  ]),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5))),
              child: chatMessage(),
            ),
            Padding(
              //top bar for returning, profile picture, and username
              padding: const EdgeInsets.only(left: 10.0, bottom: 50),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    //button
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 5),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Home()));
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new_outlined,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20.0),
                  Column(
                    children: [
                      Container(
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(friendProfilePhotoURL ??
                              "https://media.istockphoto.com/id/1495088043/vector/user-profile-icon-avatar-or-person-icon-profile-picture-portrait-symbol-default-portrait.jpg?s=612x612&w=0&k=20&c=dhV2p1JwmloBTOaGAtaA3AW1KSnjsdMt7-U_3EZElZ0="),
                          radius: 30,
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    width: 12.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName!,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontFamily: "Montserrat-R"),
                      ),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.displayName!,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    fontFamily: "Montserrat-R"),
                              ),
                              SizedBox(width: 1),
                            ],
                          ),
                          Text(
                            friendStatus == 'Online' ? 'Online' : '',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontFamily: "Montserrat-R",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            //the messaging input controller is here
            Container(
              margin: EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              alignment: Alignment.bottomCenter,
              child: Material(
                elevation: 1.0,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Send a Message",
                        hintStyle: TextStyle(
                            color: Colors.black,
                            fontFamily: "Montserrat-R",
                            fontSize: 16),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            addMessage(true);
                          },
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//functions related to database methods
import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatappdemo1/services/sharePreference.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

//integrates data to database
class DatabaseMethods {
  //get userstatus
  Future<String?> getUserStatus(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;
      return userData['status'] as String?;
    } catch (e) {
      print("error getting user status: $e");
      return null;
    }
  }

  //stream userStatus
  Stream<DocumentSnapshot> userStatusStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .handleError((error) {
      ("error getting user stream: $error");
    });
  }

  //stream userstatus for only lastupdate field
  Stream<DocumentSnapshot> userStatusStreamUpdate(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .where((snapshot) => snapshot.data()?['lastUpdate'] != null)
        .handleError((error) {
      print("error getting user stream: $error");
    });
  }

  //lastupdate since
  Future<Timestamp?> getUserLastUpdate(String userId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();
      Map<String, dynamic> userData = snapshot.data() as Map<String, dynamic>;

      // Assuming 'lastUpdate' is the field in Firestore with Timestamp type
      Timestamp? timestamp = userData['lastUpdate'];
      return timestamp;
      // if (timestamp != null) {
      //   // Convert Timestamp to DateTime and then to String
      //   DateTime dateTime = timestamp.toDate();
      //   String formattedDate =
      //       DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
      //   return formattedDate;
      // }
    } catch (e) {
      print("error getting user last update timestamp: $e");
    }
    return null; // Return null in case of any error
  }

  //user status (Online, or empty eg..), and lastupdate to detect crashes
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId);

      if ((await userDoc.get()).exists) {
        await userDoc.update({
          'status': status,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        print("Updated Status of $userId");
      } else {
        print("document with username $userId does not exists");
        // await userDoc.set({
        //   'status': status,
        // });
      }
    } catch (e) {
      print("error updating user status: $e");
    }
  }

  Future<void> offlineUserStatus(String userId, String status) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId);

      if ((await userDoc.get()).exists) {
        await userDoc.update({
          'status': status,
        });
        print("document with username $status");
      } else {
        print("document with username $userId does not exists");
        // await userDoc.set({
        //   'status': status,
        // });
      }
    } catch (e) {
      print("error updating user status: $e");
    }
  }

  //Function to handle when a user enters a chat room
  Future<void> resetUnreadCounter(chatroomId, myUserId) async {
    try {
      //Update unreadCounter to 0
      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatroomId)
          .update({
        'unreadCounter_$myUserId': 0,
      });
    } catch (e) {
      print("error Updaing Counter: $e");
    }
  }

  //unread counter function to retreive the unreadCounter
  Future<int> unreadMessagesCounter(myUserID) async {
    try {
      QuerySnapshot chatroomsQuery = await FirebaseFirestore.instance
          .collection("chatrooms")
          .where("unreadCounter_$myUserID", isGreaterThan: 0)
          .get();
      //int totalUnreadCount = 0;
      if (chatroomsQuery.size > 0) {
        //return the unreadCounter value from the first document
        return chatroomsQuery.docs[0]["unreadCounter_$myUserID"] ?? 0;
      } else {
        //return 0 if no matching document is found
        return 0;
      }
    } catch (e) {
      print("error in getUnreadMessagesCount: $e");
      return 0;
    }
  }

  //test 1
  Future<int> unread123MessagesCounter(chatRoomId, myUsername) async {
    try {
      DocumentSnapshot chatroomDoc = await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .get();
      int unreadCounter = chatroomDoc["unreadCounter_$myUsername"] ?? 0;
      return unreadCounter;
    } catch (e) {
      print("Error in getUnreadMessagesCount: $e");
      return 0;
    }
  }

  Stream<int> unreadCounterStream(chatRoomId, myUserId) {
    try {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .snapshots()
          .map((chatroomDoc) {
        return chatroomDoc["unreadCounter_$myUserId"] ?? 0;
      });
    } catch (e) {
      print("Error in unreadCounterStream: $e");
      return Stream.value(0);
    }
  }

  //create or update user's display name in firebase
  Future<void> updateDisplayName(String userId, String newName) async {
    try {
      //checl the docs
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(userId)
          .get();
      if (userDoc.exists) {
        //update name
        await userDoc.reference.update({'Fullname': newName});
      } else {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .set({'Fullname': newName});
      }
      print("Users name updated successfully");
    } catch (e) {
      print("error Updating user's name: $e");
    }
  }

  //upload photo
  Future<String?> uploadUserProfilePhoto(File imageFile) async {
    try {
      String userId = await SharedPreference().getUserID() as String;
      String fileName = 'profile_image_$userId.jpg';

      //upload image to Firebase Storage
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
      //Get the download URL
      String photoURL = await snapshot.ref.getDownloadURL();
      //update users photo URL in Firestore
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .update({'Photo': photoURL});
      //refresh the user to get the updated user data
      await FirebaseAuth.instance.currentUser!.reload();

      return photoURL;
    } catch (e) {
      print('error uploading profile photo: $e');
      return null;
    }
  }

  //get chatrooms
  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String? myUsername = await SharedPreference().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("time", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  //get user data from collection for replacing the chatroom id with the actual id
  Future<QuerySnapshot> getUserInfo(String userId) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("id", isEqualTo: userId)
        .get();
  }

  //get chat room msgs
  Future<Stream<QuerySnapshot>> getChatroomMessages(chatroomIds) async {
    //returns all the msgs by order
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatroomIds)
        .collection("chats")
        .orderBy("time", descending: true)
        .snapshots();
  }

  //function update messages
  updateLastMessageSent(
      String chatroomId, Map<String, dynamic> lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatroomId)
        .update(lastMessageInfoMap);
  }

  //add message function to firebase
  Future addMessage(String chatRoomId, String messageId,
      Map<String, dynamic> messageDataMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageDataMap);
  }

  //create chat room
  createChatRoom(
      String chatRoomId, Map<String, dynamic> chatRoomDataMap) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapshot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomDataMap);
    }
  }

  //getfriends photo when searching
  Future<String?> getFriendPhotoURL(String friendName) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where("Username", isEqualTo: friendName)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        String? photoURL = querySnapshot.docs.first.get("Photo");
        return photoURL;
      } else {
        return null;
      }
    } catch (e) {
      print("error getting photo URL: $e");
      return null;
    }
  }

  //getfriends photo when searching
  Future<String?> getFriendPhotoURLbyUserId(String friendId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .where("id", isEqualTo: friendId)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        String? photoURL = querySnapshot.docs.first.get("Photo");
        return photoURL;
      } else {
        return null;
      }
    } catch (e) {
      print("error getting photo URL: $e");
      return null;
    }
  }

  //function to get user friends and store them to a list
  Future<List<String>> getUserFriends(userId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where("id", isEqualTo: userId)
        .get();

    List<String> friendsList = [];

    querySnapshot.docs
        .forEach((DocumentSnapshot<Map<String, dynamic>> document) {
      //Check if the 'friends' field exists and is an array in the document
      if (document.data()!.containsKey('friends') &&
          document['friends'] is List<dynamic>) {
        List<dynamic> friends = document['friends'];
        friendsList.addAll(friends.map((friend) => friend.toString()));
      }
    });

    return friendsList;
  }

  //function to check if a friend request has been already sent
  Future<bool> checkFriendRequestExist(
      String senderId, String recipientId) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection("friendRequests")
        .where("senderId", isEqualTo: senderId)
        .where("recipientId", isEqualTo: recipientId)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  //check friends request status
  Future<String> checkFriendRequestStatus(
      String senderId, String recipientId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("friendRequests")
          .where("senderId", isEqualTo: senderId)
          .where("recipientId", isEqualTo: recipientId)
          .get();

      //check if there is a document in the query result
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot docSnapshot = querySnapshot.docs[0];

        //check the status of the friend request
        String status = docSnapshot.get("status") ?? "";
        return status;
      }
      return "Document is Empty";
      //no document found, implicitly return null (void)
    } catch (e) {
      print("error checking friend request status: $e");
      return "Exception error";
    }
  }

  //function to accept a friend request
  Future<void> acceptFriendRequest(String senderId, String recipientId) async {
    try {
      //get sender's username
      String? senderUsername = await getUsernameByUserId(senderId);

      //get recipient's username
      String? recipientUsername = await getUsernameByUserId(recipientId);

      if (senderUsername != null && recipientUsername != null) {
        //update sender's friends collection with recipient's username
        DocumentReference senderDoc =
            FirebaseFirestore.instance.collection("users").doc(senderId);
        await senderDoc.update({
          'friends': FieldValue.arrayUnion([recipientUsername])
        });

        //update recipient's friends collection with sender's username
        DocumentReference recipientDoc =
            FirebaseFirestore.instance.collection("users").doc(recipientId);
        await recipientDoc.update({
          'friends': FieldValue.arrayUnion([senderUsername])
        });

        //updates the friend request entry
        await FirebaseFirestore.instance
            .collection("friendRequests")
            .where("senderId", isEqualTo: senderId)
            .where("recipientId", isEqualTo: recipientId)
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) {
            doc.reference.update({'status': 'accepted'});
          });
        });
      } else {
        //handle the case where usernames are not available
        print(
            "error: Usernames not found for senderId: $senderId or recipientId: $recipientId");
      }
    } catch (e) {
      print("error accepting friend request: $e");
      //Handle the error as needed
    }
  }

  //function to reject a friend request
  Future<void> rejectFriendRequest(String senderId, String recipientId) async {
    try {
      //delete the friend request from the collection
      await FirebaseFirestore.instance
          .collection("friendRequests")
          .where("senderId", isEqualTo: senderId)
          .where("recipientId", isEqualTo: recipientId)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.update({'status': 'rejected'});
          //doc.reference.delete();
        });
      });
      //TO-DO, update the status in case we want to keep a record
      //of rejected friend requests in a separate collection.
      //we add a 'status' field and set it to 'rejected'.
    } catch (e) {
      print("error rejecting friend request: $e");
      //You might want to throw an exception or handle the error in a way that suits your application
    }
  }

  //function to get friend requests based on userId
  Future<List<String>> getFriendRequests() async {
    String userId = await SharedPreference().getUserID() as String;

    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection("friendRequests")
            .where("recipientId", isEqualTo: userId)
            .where("status", isEqualTo: "pending") //more conditions if needed
            .get();

    List<String> friendRequests = [];

    for (QueryDocumentSnapshot<Map<String, dynamic>>? documentSnapshot
        in querySnapshot.docs) {
      if (documentSnapshot != null) {
        String senderId = documentSnapshot.data()['senderId'];
        String? senderUsername = await getUsernameByUserId(senderId);
        if (senderUsername != null) {
          friendRequests.add(senderUsername);
        } else {
          friendRequests.add("Unknown");
        }
      }
    }

    return friendRequests;
  }

  //maping user details to firebase
  Future addUserDetails(
      Map<String, dynamic> userInformationMap, String id) async {
    //Add 'friends' field to the user details map
    userInformationMap['friends'] = [];
    //uploads the map to firebase, called from sign up
    return await FirebaseFirestore.instance
        .collection("users")
        .doc(id)
        .set(userInformationMap);
  }

  //send a friend request
  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    await FirebaseFirestore.instance.collection("friendRequests").add({
      'senderId': senderId,
      'recipientId': recipientId,
      'status': 'pending', //more statuses needed
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  //fetch user data from Firestore database
  Future<QuerySnapshot> getUserbyEmail(String email) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("Email", isEqualTo: email)
        .get();
  }

  //fetch userid from database by username
  /*Exception has occurred.
  FirebaseException ([cloud_firestore/resource-exhausted] Some resource has been exhausted, perhaps a per-user quota, or perhaps the entire file system is out of space.)*/
  Future<String?> getUserIdByUsername(String username) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("Username", isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    } else {
      return null;
    }
  }

  Future<String?> getUserDisplaynameByUsername(String username) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("Username", isEqualTo: username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.get("Fullname");
    } else {
      return "";
    }
  }

  //function to get username based on user ID
  Future<String?> getUsernameByUserId(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        String? username = documentSnapshot.data()!['Username'];
        print("Username for userID: $userId is $username");
        return username;
      } else {
        print("User document does not exist for userID: $userId");
        return null;
      }
    } catch (e) {
      print("error fetching username for userID: $userId, error: $e");
      return null;
    }
  }

  //Function to get usernames based on user IDs
  Future<List<String>> getUsernameByUserIds(List<String> userIds) async {
    List<String> usernames = [];

    for (String userId in userIds) {
      DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .get();

      if (documentSnapshot.exists) {
        String username = documentSnapshot.data()!['username'];
        usernames.add(username);
      }
    }

    return usernames;
  }
}

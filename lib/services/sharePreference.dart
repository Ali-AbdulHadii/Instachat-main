import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
/*persistent storage for simple data
to avoid frequent requests and load on server
like username, id, photos etc*/

class SharedPreference {
  //this saves the info locally
  static String userIdKey = "userKey";
  static String userNameKey = "userNameKey";
  static String userPhotoKey = "userPhotoKey";
  static String userEmailKey = "userEmailKey";
  static String displayUserNameKey = "displayUserName";
  static String friendsListKey = "friendsListKey";

  //set functions to save the info
  Future<bool> setUserID(String getUserId) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userIdKey, getUserId);
  }

  Future<bool> setUserName(String getUserName) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userNameKey, getUserName);
  }

  Future<bool> setUserPhoto(String getUserPhoto) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userPhotoKey, getUserPhoto);
  }

  Future<bool> setUserEmail(String getUserEmail) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(userEmailKey, getUserEmail);
  }

  //name function to used if needed
  Future<bool> setDisplayName(String getDisplayUserName) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setString(displayUserNameKey, getDisplayUserName);
  }

  //get functions to display the info
  Future<String?> getUserID() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.getString(userIdKey);
  }

  Future<String?> getUserName() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.getString(userNameKey);
  }

  Future<String?> getUserPhoto() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.getString(userPhotoKey);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.getString(userEmailKey);
  }

  //get function for name if needed
  Future<String?> getDisplayName() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.getString(displayUserNameKey);
  }

  //fuinction to set friends locally
  Future<bool> setFriendsList(List<String> friends) async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return preference.setStringList(friendsListKey, friends.toList());
  }

  //get function to get friends list
  Future<Set<String>> getFriendsList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? friendsList = prefs.getStringList(friendsListKey);
    return Set<String>.from(friendsList ?? []);
  }

  Future<bool> clearUser() async {
    SharedPreferences preference = await SharedPreferences.getInstance();
    return await preference.clear();
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/get_req_helper.dart';
import '../helper/post_req_helper.dart';
import '../model/user_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class UserService{

  static const  getUserUrl=   ApiContents.getUserUrl;
  static const  updateUserUrl=   ApiContents.updateUserUrl;
  static const  loginOutUrl=   ApiContents.loginOutUrl;
  static Future updateFCM()async{
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid=preferences.getString(SharedPreferencesConstants.uid)??"";
    String fcm="";
    try{
      final  fcmRes=await FirebaseMessaging.instance.getToken();
      fcm=fcmRes??"";
      if (kDebugMode) {
        print("Fcm Token $fcm");
      }
    }catch(e){
      if (kDebugMode) {
        print(e);
      }
    }
    Map body={
      "id":uid,
      "fcm":fcm,

    };
    final res=await PostService.postReq(updateUserUrl, body);
    return res;
  }
  static Future <UserModel?> getData()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final res=await GetService.getReq("$getUserUrl/$uid");
    if(res==null) {
      return null;
    } else {
      UserModel dataModelList = UserModel.fromJson(res);
      return dataModelList;
    }
  }
  static Future updateNotificationLastSeen()async{
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid=preferences.getString(SharedPreferencesConstants.uid)??"";

    Map body={
      "id":uid,
      "notification_seen_at":"update"
    };
    final res=await PostService.postReq(updateUserUrl, body);
    return res;
  }

  static Future logOutUser()async{
    Map body={
    };
    final res=await PostService.postReq(loginOutUrl, body);
    return res;
  }
}
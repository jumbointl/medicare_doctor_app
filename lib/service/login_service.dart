import 'package:flutter/material.dart';

import '../helper/post_req_helper.dart';
import '../model/user_model.dart';
import '../utilities/api_content.dart';

class LoginService{

  static const  loginUrl=   ApiContents.loginUrl;

  static List<UserModel> dataFromJson (jsonDecodedData){
    return List<UserModel>.from(jsonDecodedData.map((item)=>UserModel.fromJson(item)));
  }

  static Future login(
      {
        required String email,
        required String password,
      }
      )async{
    Map body={
      'email': email,
      'password':password
    };
    final res=await PostService.postReq(loginUrl, body);
    return res;
  }

  static Future<dynamic> loginWithGoogle({
    required String idToken,
    required String email,
  }) async {
    try {
      final response = await PostService.postReq(
        ApiContents.loginGoogleDoctorUrl,
        {
          'id_token': idToken,
          'email': email.trim().toLowerCase(),
        },
      );

      return response;
    } catch (e) {
      debugPrint("Doctor loginWithGoogle error: $e");
      return null;
    }
  }
}
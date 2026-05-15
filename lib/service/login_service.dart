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

  /// POST /v1/login/dev — login para desarrollo + impersonate opcional.
  /// El backend gatekeepea por rol (Super Admin o Developer). Si
  /// `impersonateEmail` viene vacío, autentica al dev con sus credenciales.
  /// Si viene poblado, emite token a nombre del usuario de ese email sin
  /// pedir su password. Response incluye `impersonator_id` + `impersonator_email`
  /// cuando hubo suplantación.
  static Future<dynamic> loginDev({
    required String email,
    required String password,
    String? impersonateEmail,
  }) async {
    final Map<String, dynamic> body = {
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    final imp = impersonateEmail?.trim() ?? '';
    if (imp.isNotEmpty) {
      body['impersonate_email'] = imp.toLowerCase();
    }
    final res = await PostService.postReq(ApiContents.loginDevUrl, body);
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
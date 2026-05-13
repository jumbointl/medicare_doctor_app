import 'dart:convert';
import 'package:dio/dio.dart';
import '../helper/route_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/toast_message.dart';
import 'refresh_session.dart';
import 'package:get/get.dart';
class PostService{
  // Llama POST /v1/refresh-dynamic-key con el JWT actual y devuelve el
  // nuevo dynamic_key. Devuelve null si falla.
  static Future<String?> _tryRefreshDynamicKey(String token) async {
    try {
      final dio = Dio(BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Content-Type': 'application/json',
          'authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final res = await dio.post(ApiContents.refreshDynamicKeyUrl);
      if (res.statusCode == 200 && res.data is Map) {
        final dynKey = res.data['dynamic_key']?.toString();
        if (dynKey != null && dynKey.isNotEmpty) return dynKey;
      }
    } catch (e) {
      if (kDebugMode) print('refreshDynamicKey error: $e');
    }
    return null;
  }

  static Future postReq(String url, body, {bool isRetry = false})async {
    if (kDebugMode) {
      print("======Url==========");
      print(url);
      print("======Send Data==========");
      print(body);
    }
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final token=  preferences.getString(SharedPreferencesConstants.token)??"";
    final dynamicKey =
        preferences.getString(SharedPreferencesConstants.dynamicKey) ?? "";
    try {
      var dio = Dio(
          BaseOptions(
            headers: {
              'x-api-key': AppConstants.apiKey, // Set it here
              'Content-Type': 'application/json',
            },
          )
      );
      dio.options.headers["authorization"] = "Bearer $token";
      // Solo cuando lo tenemos (medicare-node-api lo emite desde 2026-05-08).
      if (dynamicKey.isNotEmpty) {
        dio.options.headers["x-dynamic-key"] = dynamicKey;
      }
       dio.options.headers["contentType"] = "application/x-www-form-urlencoded";
      dio.options.validateStatus = (status) {
        // Allow 200 and 401 status codes, so they don't throw exceptions
        debugPrint("DOCTOR LOGOUT TOKEN = $token");
        return status! < 500;
      };
      final response = await dio.post(url, data: body);
      if (kDebugMode) {
        print("==========URL Response==========");
        print(response);
      }
      if (response.statusCode == 401) {
        // 401 con header X-Auth-Reason: dynamic-key → server rechazó el
        // dynamic_key. Aplicar regla del login_provider:
        //   google   → refresh-dynamic-key + retry una vez (anti-bucle).
        //   password → logOut.
        final reason = response.headers.value('x-auth-reason') ??
            response.headers.value('X-Auth-Reason');
        if (!isRetry && reason == 'dynamic-key' && token.isNotEmpty) {
          final provider = preferences
                  .getString(SharedPreferencesConstants.loginProvider) ??
              '';
          if (provider == 'google') {
            final newKey = await _tryRefreshDynamicKey(token);
            if (newKey != null) {
              await preferences.setString(
                SharedPreferencesConstants.dynamicKey,
                newKey,
              );
              return await postReq(url, body, isRetry: true);
            }
          }
          IToastMsg.showMessage("Session expired. Please log in again.");
          logOut();
          return null;
        }

        // Refresh-token Fase 2 (2026-05-13). 401 sin reason=dynamic-key
        // y con sesión activa: el session-JWT (12h) probablemente
        // expiró. Intentamos renovarlo con el refresh_token persistido
        // antes de forzar logout. Excluimos /login* (un 401 ahí es
        // rechazo de credenciales, no sesión expirada) y /refresh*
        // (anti-recursión).
        final isLoginEndpoint = url.contains('/login');
        final isRefreshEndpoint =
            url.contains('/refresh') || url.contains('/refresh-dynamic-key');
        if (!isRetry &&
            !isLoginEndpoint &&
            !isRefreshEndpoint &&
            token.isNotEmpty) {
          final ok = await tryRefreshSession();
          if (ok) {
            return await postReq(url, body, isRetry: true);
          }
        }

        IToastMsg.showMessage("Session expired. Please log in again.");
        logOut();
        return null;
      }
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.toString());
        if (kDebugMode) {
          print("==========Response==========");
          print(jsonData);
        }
        if (jsonData['response'] == 201) {
          if (jsonData['message'] == "error") {
            IToastMsg.showMessage("Something went wrong");
          } else {
            IToastMsg.showMessage(jsonData['message']);
          }
          return null;
        }
        else if (jsonData['response'] == 200){
          return jsonData;
       }
      }else {
        IToastMsg.showMessage("Something went wrong");
        return null;
      }
    }catch(e){
       if (kDebugMode) {
         print(e);
       }
       IToastMsg.showMessage("Something went wrong");
       return null;
    }

  }
  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    IToastMsg.showMessage("Logout");

    Get.offAllNamed(RouteHelper.getHomePageRoute());
  }

}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';
import 'refresh_session.dart';

class GetService {
  // Refresh-token Fase 2 (2026-05-13). Detecta 401 desde DioException
  // (cuando validateStatus default deja que Dio throwee) y pide a
  // tryRefreshSession() renovar el JWT. Anti-bucle vía isRetry flag.
  static bool _is401(Object e) {
    if (e is DioException) {
      return e.response?.statusCode == 401;
    }
    return false;
  }

  // Lee Bearer JWT + dynamic-key de SharedPreferences y los pone como
  // headers — espejo de lo que ya hace PostService. Sin estos headers
  // medicare-node-api responde 401 y todos los GET del dashboard caen
  // en silencio (los controllers no muestran toast, solo `Algo salió mal`).
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token) ?? "";
    final dynamicKey =
        prefs.getString(SharedPreferencesConstants.dynamicKey) ?? "";
    final h = <String, String>{
      'x-api-key': AppConstants.apiKey,
      'Content-Type': 'application/json',
    };
    if (token.isNotEmpty) h['authorization'] = "Bearer $token";
    if (dynamicKey.isNotEmpty) h['x-dynamic-key'] = dynamicKey;
    return h;
  }

  static Future getReqWithBodY(url, Map<String, dynamic>? body,
      {bool isRetry = false}) async {
    final headers = await _authHeaders();
    var dio = Dio(BaseOptions(headers: headers));
    try {
      if (kDebugMode) {
        print("$url");
        print("$body");
      }
      final response = await dio.get(url, queryParameters: body);
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response==============");
        print(response);
      }
      if (response.statusCode == 200) {
        final jsonData = await json.decode(response.toString());
        if (jsonData['response'] == 200) {
          if (jsonData['data'] != null) {
            return jsonData['data'];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null; //if any error occurs then it return a blank list
      }
    } catch (e) {
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response Error==============");
        print(e);
      }
      if (!isRetry && _is401(e)) {
        final ok = await tryRefreshSession();
        if (ok) return getReqWithBodY(url, body, isRetry: true);
      }
      return null;
    }
  }

  static Future getReqWithBody(String url, Map<String, dynamic> body,
      {bool isRetry = false}) async {
    final headers = await _authHeaders();
    var dio = Dio(BaseOptions(headers: headers));
    try {
      final response = await dio.get(url, queryParameters: body);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("==================URL==============");
          print(url);
          print("==================BODY==============");
          print(body);
          print("==================Response==============");
          print(response);
        }
        final jsonData = await json.decode(response.toString());
        if (jsonData['response'] == 200) {
          if (jsonData['data'] != null) {
            return jsonData['data'];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null; //if any error occurs then it return a blank list
      }
    } catch (e) {
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response Error==============");
        print(e);
      }
      if (!isRetry && _is401(e)) {
        final ok = await tryRefreshSession();
        if (ok) return getReqWithBody(url, body, isRetry: true);
      }
      return null;
    }
  }

  static Future getReq(String url, {bool isRetry = false}) async {
    final headers = await _authHeaders();
    var dio = Dio(BaseOptions(headers: headers));
    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("==================URL==============");
          print(url);
          print("==================Response==============");
          print(response);
        }
        final jsonData = await json.decode(response.toString());
        if (jsonData['response'] == 200) {
          if (jsonData['data'] != null) {
            return jsonData['data'];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null; //if any error occurs then it return a blank list
      }
    } catch (e) {
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response Error==============");
        print(e);
      }
      if (!isRetry && _is401(e)) {
        final ok = await tryRefreshSession();
        if (ok) return getReq(url, isRetry: true);
      }
      return null;
    }
  }
}

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utilities/app_constans.dart';

class GetService{

  static Future getReqWithBodY(url,Map<String, dynamic>? body)async {
    var dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey, // Set it here
            'Content-Type': 'application/json',
          },
        )
    );
    try {
      if (kDebugMode) {
        print("$url");
        print("$body");
      }
      final response= await dio.get(url,
          queryParameters: body
      );
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response==============");
        print(response);
      }
      if (response.statusCode == 200) {
        final jsonData=await json.decode(response.toString());
        if(jsonData['response']==200) {
          if(jsonData['data']!=null){
            return jsonData['data'];
          }else {
            return null;
          }
        }
        else {
          return null;
        }
      } else {
        return null; //if any error occurs then it return a blank list
      }
    }
    catch (e) {
      if (kDebugMode) {
        print("==================URL==============");
        print(url);
        print("==================Response Error==============");
        print(e);
      }
      return null;
    }

  }
  static Future getReqWithBody(String url,Map<String, dynamic> body)async {
    var dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey, // Set it here
            'Content-Type': 'application/json',
          },
        )
    );
    try {
      final response= await dio.get(url,queryParameters:body);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("==================URL==============");
          print(url);
          print("==================BODY==============");
          print(body);
          print("==================Response==============");
          print(response);
        }
        final jsonData=await json.decode(response.toString());
        if(jsonData['response']==200) {
          if(jsonData['data']!=null){
            return jsonData['data'];
          }else {
            return null;
          }
        }
        else {
          return null;
        }

      } else {
        return null; //if any error occurs then it return a blank list
      }
    }
    catch (e) {
      return null;
    }

  }
  static Future getReq(String url)async {
    var dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey, // Set it here
            'Content-Type': 'application/json',
          },
        )
    );
    try {
      final response= await dio.get(url);
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("==================URL==============");
          print(url);
          print("==================Response==============");
          print(response);
        }
        final jsonData=await json.decode(response.toString());
        if(jsonData['response']==200) {
          if(jsonData['data']!=null){
            return jsonData['data'];
          }else {
            return null;
          }
        }
        else {
          return null;
        }

      } else {
        return null; //if any error occurs then it return a blank list
      }
    }
    catch (e) {
      return null;
    }

  }

}
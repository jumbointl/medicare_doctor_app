import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';

/// Wraps the doctor-side endpoints that touch `users` / `doctors`:
///   POST /api/v1/update_doctor          → personal fields + image
///   POST /api/v1/remove_doctor_image    → clear avatar
class UpdateDoctorService {
  /// Update personal fields. Pass only the values you want to change.
  static Future<bool> updatePersonal({
    required int userId,
    String? fName,
    String? lName,
    String? email,
    String? phone,
    String? isdCode,
    String? dob,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? description,
    String? specialization,
    int? exYear,
  }) async {
    final body = <String, dynamic>{
      'id': userId,
    };

    void putIf(String key, Object? value) {
      if (value != null) body[key] = value;
    }

    putIf('f_name', fName);
    putIf('l_name', lName);
    putIf('email', email);
    putIf('phone', phone);
    putIf('isd_code', isdCode);
    putIf('dob', dob);
    putIf('gender', gender);
    putIf('address', address);
    putIf('city', city);
    putIf('state', state);
    putIf('postal_code', postalCode);
    putIf('description', description);
    putIf('specialization', specialization);
    putIf('ex_year', exYear);

    final res = await PostService.postReq(
      ApiContents.updateDoctorUrl,
      body,
    );
    return _ok(res);
  }

  /// Upload a new avatar image. Sends multipart/form-data because
  /// PostService.postReq is JSON-only.
  static Future<bool> uploadImage({
    required int userId,
    required File image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString(SharedPreferencesConstants.token) ?? '';

    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey,
            'authorization': 'Bearer $token',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final formData = FormData.fromMap({
        'id': userId,
        'image': await MultipartFile.fromFile(image.path),
      });

      final response = await dio.post(
        ApiContents.updateDoctorUrl,
        data: formData,
      );

      if (kDebugMode) {
        print('==========updateDoctor uploadImage Response==========');
        print(response);
      }

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          return data['response'] == 200 || data['status'] == true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('uploadImage error: $e');
      return false;
    }
  }

  /// Clear the doctor's avatar.
  static Future<bool> removeImage({required int userId}) async {
    final res = await PostService.postReq(
      ApiContents.removeDoctorImageUrl,
      {'id': userId},
    );
    return _ok(res);
  }

  static bool _ok(dynamic res) {
    if (res == null) return false;
    if (res is Map) {
      if (res['status'] == true) return true;
      if (res['response'] == 200) return true;
    }
    return false;
  }
}

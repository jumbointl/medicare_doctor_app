// Panel TV (Fase 2). Endpoints en medicare-node-api:
//   POST  /v1/calls/next               { clinic_id }                → auto
//   POST  /v1/calls                    { appointment_id }           → manual
//   POST  /v1/patient-calls/:id/recall                              → re-llamar
//   PATCH /v1/patient-calls/:id/attend                              → cerrar como atendido
//   PATCH /v1/patient-calls/:id/no-show                             → cerrar sin atender
//   GET   /v1/clinics/:id/active-calls?limit=N                      → poll/sync
//
// Cliente Dio fresh por call — más simple que reusar PostService que ya
// hace muchas cosas (Laravel-style 401 dispatch, refresh dynamic-key, etc.)
// y no soporta PATCH. Para piloto Fase 2 es suficiente con error → null.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';

class PatientCallsService {
  static Future<Dio> _client() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token) ?? '';
    final dynKey = prefs.getString(SharedPreferencesConstants.dynamicKey) ?? '';
    final dio = Dio(
      BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'authorization': 'Bearer $token',
          if (dynKey.isNotEmpty) 'x-dynamic-key': dynKey,
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        // Bizerr Laravel devuelve HTTP 200 con response:201 → no es excepción.
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    return dio;
  }

  static Future<Map<String, dynamic>?> callNext(int clinicId) {
    return _post(ApiContents.callNextUrl, {'clinic_id': clinicId});
  }

  static Future<Map<String, dynamic>?> callManual(int appointmentId) {
    return _post(ApiContents.callManualUrl, {'appointment_id': appointmentId});
  }

  static Future<Map<String, dynamic>?> recall(int callId) {
    return _post('${ApiContents.patientCallsBase}/$callId/recall', null);
  }

  static Future<Map<String, dynamic>?> attend(int callId) {
    return _patch('${ApiContents.patientCallsBase}/$callId/attend');
  }

  static Future<Map<String, dynamic>?> noShow(int callId) {
    return _patch('${ApiContents.patientCallsBase}/$callId/no-show');
  }

  /// Devuelve la lista de patient_calls activos de la clínica de hoy (called
  /// + recalled). Usa para indicarle al doctor qué pacientes ya están en
  /// pantalla en el panel TV.
  static Future<List<dynamic>> activeCalls(int clinicId, {int limit = 100}) async {
    try {
      final dio = await _client();
      final res = await dio.get(
        '${ApiContents.clinicsBase}/$clinicId/active-calls',
        queryParameters: {'limit': limit},
      );
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
        return res.data['data'] as List;
      }
    } catch (e) {
      if (kDebugMode) print('[PatientCallsService] activeCalls failed: $e');
    }
    return const [];
  }

  static Future<Map<String, dynamic>?> _post(String url, Object? data) async {
    try {
      final dio = await _client();
      final res = await dio.post(url, data: data);
      return _asMap(res);
    } catch (e) {
      if (kDebugMode) print('[PatientCallsService] POST $url failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _patch(String url) async {
    try {
      final dio = await _client();
      final res = await dio.patch(url);
      return _asMap(res);
    } catch (e) {
      if (kDebugMode) print('[PatientCallsService] PATCH $url failed: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _asMap(Response res) {
    if (res.statusCode == 200 && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return null;
  }
}

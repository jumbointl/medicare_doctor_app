import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'agora_session_cache.dart';

class AgoraSessionStorage {
  static const String _prefix = 'agora_session_';

  static String _key({
    required int appointmentId,
    required bool isDoctor,
  }) {
    return '$_prefix${isDoctor ? "doctor" : "user"}_$appointmentId';
  }

  static Future<void> saveSession(AgoraSessionCache session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(
        appointmentId: session.appointmentId,
        isDoctor: session.isDoctor,
      ),
      jsonEncode(session.toJson()),
    );
  }

  static Future<AgoraSessionCache?> getValidSession({
    required int appointmentId,
    required bool isDoctor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _key(appointmentId: appointmentId, isDoctor: isDoctor),
    );

    if (raw == null || raw.isEmpty) {
      return null;
    }

    final session = AgoraSessionCache.tryParse(raw);
    if (session == null) {
      await removeSession(appointmentId: appointmentId, isDoctor: isDoctor);
      return null;
    }

    if (session.isExpired) {
      await removeSession(appointmentId: appointmentId, isDoctor: isDoctor);
      return null;
    }

    return session;
  }

  static Future<void> removeSession({
    required int appointmentId,
    required bool isDoctor,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      _key(appointmentId: appointmentId, isDoctor: isDoctor),
    );
  }

  static Future<void> clearExpiredSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) {
        await prefs.remove(key);
        continue;
      }

      final session = AgoraSessionCache.tryParse(raw);
      if (session == null || session.isExpired) {
        await prefs.remove(key);
      }
    }
  }
}
import 'dart:convert';

class AgoraSessionCache {
  final int appointmentId;
  final String appId;
  final String channelName;
  final int uid;
  final String token;
  final int expiresAt;
  final bool isDoctor;
  final int joinClosesAt;

  AgoraSessionCache({
    required this.appointmentId,
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
    required this.expiresAt,
    required this.isDoctor,
    required this.joinClosesAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'appointment_id': appointmentId,
      'app_id': appId,
      'channel_name': channelName,
      'uid': uid,
      'token': token,
      'expires_at': expiresAt,
      'is_doctor': isDoctor,
      'join_closes_at': joinClosesAt,
    };
  }

  factory AgoraSessionCache.fromJson(Map<String, dynamic> json) {
    return AgoraSessionCache(
      appointmentId: json['appointment_id'] ?? 0,
      appId: json['app_id'] ?? '',
      channelName: json['channel_name'] ?? '',
      uid: json['uid'] ?? 0,
      token: json['token'] ?? '',
      expiresAt: json['expires_at'] ?? 0,
      isDoctor: json['is_doctor'] ?? false,
      joinClosesAt: json['join_closes_at'] ?? 0,
    );
  }

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch ~/ 1000 >= expiresAt;

  static AgoraSessionCache? tryParse(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AgoraSessionCache.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
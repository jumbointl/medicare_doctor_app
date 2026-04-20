class AgoraJoinData {
  final String appId;
  final String channelName;
  final int uid;
  final String token;
  final String role;
  final int appointmentId;
  final int expiresAt;
  final int joinClosesAt;
  final bool isDoctor;
  final bool isPatient;

  AgoraJoinData({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
    required this.role,
    required this.appointmentId,
    required this.expiresAt,
    required this.joinClosesAt,
    required this.isDoctor,
    required this.isPatient,
  });

  factory AgoraJoinData.fromJson(Map<String, dynamic> json) {
    return AgoraJoinData(
      appId: json['appId'] ?? '',
      channelName: json['channelName'] ?? '',
      uid: json['uid'] ?? 0,
      token: json['token'] ?? '',
      role: json['role'] ?? '',
      appointmentId: json['appointment_id'] ?? 0,
      expiresAt: json['expires_at'] ?? 0,
      joinClosesAt: json['join_closes_at'] ?? 0,
      isDoctor: json['is_doctor'] ?? false,
      isPatient: json['is_patient'] ?? false,
    );
  }
}
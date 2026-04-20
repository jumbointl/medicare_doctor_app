import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agora_session_cache.dart';
import 'agora_call_page.dart';
import 'agora_video_service.dart';
import 'agora_session_storage.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/toast_message.dart';

Future<int> _getCurrentUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString(SharedPreferencesConstants.uid) ?? '0';
  return int.tryParse(uid) ?? 0;
}

Future<void> openAgoraCallWithCache({
  required int appointmentId,
  required bool isDoctor,
  String? title,
  void Function(Map<String, dynamic> debug)? onDebugData,
}) async {
  final cached = await AgoraSessionStorage.getValidSession(
    appointmentId: appointmentId,
    isDoctor: isDoctor,
  );

  if (cached != null) {
    onDebugData?.call({
      'source': 'cache',
      'channelName': cached.channelName,
      'uid': cached.uid,
      'appId': cached.appId,
      'token': cached.token,
      'isDoctor': isDoctor,
      'join_closes_at' : cached.joinClosesAt,
    });

    Get.to(
          () => AgoraCallPage(
        appId: cached.appId,
        token: cached.token,
        channelName: cached.channelName,
        uid: cached.uid,
        title: title ?? (isDoctor ? 'Iniciar video' : 'Unirse a video'),
        joinClosesAt: cached.joinClosesAt,
      ),
    );
    return;
  }

  final userId = await _getCurrentUserId();

  final result = await AgoraVideoService.getJoinData(
    appointmentId: appointmentId,
    userId: userId,
  );

  if (!result.success || result.data == null) {
    IToastMsg.showMessage(result.message);
    return;
  }

  final session = AgoraSessionCache(
    appointmentId: appointmentId,
    appId: result.data!.appId,
    channelName: result.data!.channelName,
    uid: result.data!.uid,
    token: result.data!.token,
    expiresAt: result.data!.expiresAt,
    isDoctor: isDoctor,
    joinClosesAt: result.data?.joinClosesAt ?? 0,
  );

  onDebugData?.call({
    'source': 'fresh',
    'channelName': result.data!.channelName,
    'uid': result.data!.uid,
    'appId': result.data!.appId,
    'token': result.data!.token,
    'isDoctor': isDoctor,
    'join_closes_at' : result.data?.joinClosesAt ?? 0,

  });

  await AgoraSessionStorage.saveSession(session);

  Get.to(
        () => AgoraCallPage(
      appId: session.appId,
      token: session.token,
      channelName: session.channelName,
      uid: session.uid,
      title: title ?? (isDoctor ? 'Iniciar video' : 'Unirse a video'),
      joinClosesAt: result.data?.joinClosesAt ?? 0,
    ),
  );
}
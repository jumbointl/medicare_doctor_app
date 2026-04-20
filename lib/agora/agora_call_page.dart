import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraCallPage extends StatefulWidget {
  const AgoraCallPage({
    super.key,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.title,
    required this.joinClosesAt,
  });

  final String appId;
  final String token;
  final String channelName;
  final String title;
  final int uid;
  final int joinClosesAt;

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  late final RtcEngine _engine;

  int? _remoteUid;
  bool _joined = false;
  bool _micMuted = false;
  bool _cameraOff = false;
  bool _isInitializing = true;

  String _lastAgoraError = '';
  String _connectionStateText = 'Conectando...';
  Timer? _closeInfoTimer;
  @override
  void initState() {
    super.initState();
    _startCloseInfoTimer();
    _initAgora();
  }
  @override
  void dispose() {
    _closeInfoTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }
  void _startCloseInfoTimer() {
    _closeInfoTimer?.cancel();

    _closeInfoTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      await _handleAutoCloseIfNeeded();
      if (!mounted) return;
      setState(() {});
    });
  }
  Future<void> _initAgora() async {
    final statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted = statuses[Permission.camera]?.isGranted ?? false;

    if (!micGranted || !camGranted) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _lastAgoraError =
        'Permisos faltantes. Cámara: $camGranted / Micrófono: $micGranted';
        _connectionStateText = 'Permisos denegados';
      });
      return;
    }

    _engine = createAgoraRtcEngine();

    await _engine.initialize(
      RtcEngineContext(
        appId: widget.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          setState(() {
            _joined = true;
            _lastAgoraError = '';
            _connectionStateText = 'Conectado';
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (!mounted) return;
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (
            RtcConnection connection,
            int remoteUid,
            UserOfflineReasonType reason,
            ) {
          if (!mounted) return;
          setState(() {
            _remoteUid = null;
          });
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          if (!mounted) return;
          setState(() {
            _joined = false;
            _remoteUid = null;
            _connectionStateText = 'Finalizada';
          });
        },
        onError: (ErrorCodeType err, String msg) {
          if (!mounted) return;
          setState(() {
            _lastAgoraError = msg.isEmpty ? 'Error Agora: $err' : 'Error Agora: $err - $msg';
          });
        },
        onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
            ) {
          if (!mounted) return;
          setState(() {
            _connectionStateText = '${state.name} / ${reason.name}';
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.enableAudio();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );

    if (!mounted) return;
    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _toggleMic() async {
    _micMuted = !_micMuted;
    await _engine.muteLocalAudioStream(_micMuted);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    _cameraOff = !_cameraOff;
    await _engine.muteLocalVideoStream(_cameraOff);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
  }

  Future<void> _leaveCall() async {
    await _engine.leaveChannel();
    if (!mounted) return;
    Navigator.of(context).pop();
  }
  Future<void> _handleAutoCloseIfNeeded() async {
    if (widget.joinClosesAt <= 0) return;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (nowSeconds < widget.joinClosesAt) return;

    _closeInfoTimer?.cancel();

    if (mounted) {
      setState(() {
        _lastAgoraError = '';
        _connectionStateText = 'Consulta finalizada';
      });
    }

    try {
      await _engine.leaveChannel();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pop();
  }
  String _formatCloseTime() {
    if (widget.joinClosesAt <= 0) return '--:--';
    final date = DateTime.fromMillisecondsSinceEpoch(
      widget.joinClosesAt * 1000,
    );
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _buildLocalVideo() {
    if (_cameraOff) {
      return const ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteUid == null) {
      return const ColoredBox(
        color: Colors.black87,
        child: Center(
          child: Text(
            'Esperando al otro usuario...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(uid: _remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _buildStatusBar() {
    final bool hasError = _lastAgoraError.trim().isNotEmpty;
    final bool closingSoon = _isClosingSoon;

    final Color statusColor = hasError
        ? Colors.redAccent
        : closingSoon
        ? Colors.orange
        : Colors.green;

    final IconData statusIcon = hasError
        ? Icons.error
        : closingSoon
        ? Icons.warning_amber_rounded
        : Icons.check_circle;

    final String statusText = hasError
        ? _lastAgoraError
        : closingSoon
        ? 'Cierra pronto (${_formatRemainingCloseTime()})'
        : (_joined ? 'Conexión OK' : _connectionStateText);
    if (!hasError && _secondsUntilClose() == 0 && widget.joinClosesAt > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.58),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.access_time_filled, color: Colors.orange, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Tiempo finalizado. Cerrando consulta...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.58),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              statusText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Cierre: ${_formatCloseTime()}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton(
          heroTag: 'mic',
          onPressed: _toggleMic,
          child: Icon(_micMuted ? Icons.mic_off : Icons.mic),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'end',
          backgroundColor: Colors.red,
          onPressed: _leaveCall,
          child: const Icon(Icons.call_end),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'camera',
          onPressed: _toggleCamera,
          child: Icon(_cameraOff ? Icons.videocam_off : Icons.videocam),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'switch',
          onPressed: _switchCamera,
          child: const Icon(Icons.cameraswitch),
        ),
      ],
    );
  }
  int _secondsUntilClose() {
    if (widget.joinClosesAt <= 0) return 0;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = widget.joinClosesAt - nowSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get _isClosingSoon => _secondsUntilClose() > 0 && _secondsUntilClose() <= 300;

  String _formatRemainingCloseTime() {
    final seconds = _secondsUntilClose();
    if (seconds <= 0) return '00:00';

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_joined ? 'Connected' : widget.title),
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Positioned.fill(child: _buildRemoteVideo()),
          Positioned(
            right: 16,
            top: 16,
            width: 120,
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildLocalVideo(),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBar(),
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallService {
  static const String appId = "5b884bb2629c4b6e85cf057492f5e847"; // App ID de Agora

  RtcEngine? _engine;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions (only for mobile, on web browser handles it)
      if (!kIsWeb) {
        await [Permission.microphone, Permission.camera].request();
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine!.enableVideo();
      await _engine!.startPreview();
      
      _isInitialized = true;
      debugPrint("Agora Engine Initialized successfully");
    } catch (e) {
      debugPrint("Error initializing Agora Engine: $e");
      rethrow;
    }
  }

  Future<void> joinChannel(String channelName, int uid) async {
    try {
      if (!_isInitialized) await initialize();

      await _engine!.joinChannel(
        token: '', // Using Test Mode (No Token)
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
      debugPrint("Joining channel: $channelName with uid: $uid");
    } catch (e) {
      debugPrint("Error joining channel: $e");
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
    }
  }

  Future<void> dispose() async {
    if (_engine != null) {
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }

  RtcEngine? get engine => _engine;
}

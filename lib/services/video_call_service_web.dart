/// Stub for web — Agora is not supported on Flutter Web.
/// The real implementation is in video_call_service.dart (used on native).
class VideoCallService {
  /// Always null on web — Agora engine is unavailable.
  RtcEngineStub? get engine => null;

  Future<void> initialize() async {
    // no-op on web (will not be called due to kIsWeb guard)
  }

  Future<void> joinChannel(String channelName, int uid) async {
    // no-op on web
  }

  Future<void> leaveChannel() async {}
  Future<void> dispose() async {}
}

/// Stub replacement for Agora's RtcEngine on web.
class RtcEngineStub {
  Future<void> muteLocalAudioStream(bool muted) async {}
  Future<void> muteLocalVideoStream(bool muted) async {}
}

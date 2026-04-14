import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../services/call_service.dart';

class CallProvider extends ChangeNotifier {
  bool _isIncomingCall = false;
  bool _isAudioOnly = false;
  String? _callerId;
  String? _callerName;
  String? _channelId;
  StreamSubscription? _subscription;

  // Fired when the remote party ends the call so CallPage can close itself.
  VoidCallback? onRemoteCallEnded;

  bool get isIncomingCall => _isIncomingCall;
  bool get isAudioOnly => _isAudioOnly;
  String? get callerName => _callerName;
  String? get callerId => _callerId;
  String? get channelId => _channelId;

  void init() async {
    if (_subscription != null) return; // Already subscribed

    final user = await Amplify.Auth.getCurrentUser();
    final myId = user.userId;

    const subDoc = 'subscription OnCreateMessage { '
        'onCreateMessage { id senderId receiverId content createdAt } }';

    final subRequest = GraphQLRequest<String>(
      document: subDoc,
      authorizationMode: APIAuthorizationType.apiKey,
    );

    _subscription = Amplify.API.subscribe(subRequest).listen((event) {
      if (event.data != null) {
        try {
          final decoded = jsonDecode(event.data!);
          final message = decoded['onCreateMessage'];

          if (message != null && message['receiverId'] == myId) {
            final content = message['content'] as String;
            if (content.startsWith(CallService.signalPrefix)) {
              _handleSignal(message['senderId'], content);
            }
          }
        } catch (e) {
          debugPrint('Error parsing call signal: $e');
        }
      }
    });

    debugPrint('CallProvider initialized and listening for signals');
  }

  void _handleSignal(String senderId, String content) {
    final parts = content.split(':');
    if (parts.length < 2) return;

    final signalParts = parts[1].split('|');
    final action = signalParts[0];

    if (action == 'CALL_REQUEST') {
      final channel = signalParts[1];
      final name = signalParts.length > 2 ? signalParts[2] : "Unknown Caller";
      final type = signalParts.length > 3 ? signalParts[3] : "video";

      _isIncomingCall = true;
      _isAudioOnly = type == 'audio';
      _callerId = senderId;
      _channelId = channel;
      _callerName = name;
      notifyListeners();

    } else if (action == 'CALL_ENDED') {
      // The remote party hung up — fire the callback so CallPage can pop.
      debugPrint('Remote party ended the call (channel: ${signalParts.elementAtOrNull(1)})');
      onRemoteCallEnded?.call();

    } else if (action == 'CALL_REJECTED' || action == 'CALL_ACCEPTED') {
      // Handle call responses if needed
    }
  }

  void acceptCall(BuildContext context, Function(String, String, bool) onAccept) {
    final channel = _channelId;
    final name = _callerName;
    final isAudio = _isAudioOnly;
    _isIncomingCall = false;
    notifyListeners();

    if (channel != null && name != null) {
      onAccept(channel, name, isAudio);
    }
  }

  void rejectCall() {
    _isIncomingCall = false;
    _isAudioOnly = false;
    _callerId = null;
    _callerName = null;
    _channelId = null;
    notifyListeners();
  }

  /// Call this on sign out so that init() can be called afresh on next login.
  Future<void> reset() async {
    await _subscription?.cancel();
    _subscription = null;
    _isIncomingCall = false;
    _isAudioOnly = false;
    _callerId = null;
    _callerName = null;
    _channelId = null;
    onRemoteCallEnded = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

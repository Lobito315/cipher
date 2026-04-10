import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'services/video_call_service.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final String remoteUserName;
  final bool isAudioOnly;

  const CallPage({
    super.key,
    required this.channelName,
    required this.remoteUserName,
    this.isAudioOnly = false,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _videoCallService = VideoCallService();
  int? _remoteUid;
  int? _localUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoOff = false;
  bool _showDialPad = false;
  String _dialedNumbers = "";

  @override
  void initState() {
    super.initState();
    _videoOff = widget.isAudioOnly;
    _initAgora();
  }

  Future<void> _initAgora() async {
    await _videoCallService.initialize();
    
    _videoCallService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined: ${connection.localUid}");
          setState(() {
            _localUid = connection.localUid;
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Remote user offline: $remoteUid");
          setState(() {
            _remoteUid = null;
          });
          // Optionally auto-hangup if peer leaves
          Navigator.pop(context);
        },
      ),
    );

    await _videoCallService.joinChannel(widget.channelName, 0);
  }

  @override
  void dispose() {
    _videoCallService.leaveChannel();
    _videoCallService.dispose();
    super.dispose();
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _videoCallService.engine?.muteLocalAudioStream(_muted);
  }

  void _onToggleVideo() {
    setState(() {
      _videoOff = !_videoOff;
    });
    _videoCallService.engine?.muteLocalVideoStream(_videoOff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C07),
      body: Stack(
        children: [
          // Remote Video or Avatar
          Center(
            child: widget.isAudioOnly
                ? _buildAudioCallUI()
                : (_remoteUid != null
                    ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _videoCallService.engine!,
                          canvas: VideoCanvas(uid: _remoteUid),
                          connection: RtcConnection(channelId: widget.channelName),
                        ),
                      )
                    : _buildWaitingState()),
          ),

          // Local Video (Preview) - Only show if not audio call
          if (!widget.isAudioOnly)
            Positioned(
              top: 60,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    border: Border.all(color: const Color(0xFFBEF263), width: 1),
                  ),
                  child: _localUserJoined && !_videoOff
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _videoCallService.engine!,
                            canvas: VideoCanvas(uid: _localUid ?? 0),
                          ),
                        )
                      : const Center(child: Icon(Icons.person, color: Color(0xFFBEF263))),
                ),
              ),
            ),

          // Header Info
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFFBEF263), size: 14),
                    SizedBox(width: 4),
                    Text(
                      "End-to-End Encrypted",
                      style: TextStyle(color: Color(0xFFBEF263), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),

          // Dial Pad Overlay
          if (_showDialPad)
            Positioned.fill(
              child: _buildDialPad(),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFFBEF263)),
        const SizedBox(height: 20),
        Text(
          "Waiting for ${widget.remoteUserName}...",
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2210).withAlpha(153), // 0.6 opacity
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x33BEF263)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                _buildControlButton(
                  icon: _muted ? Icons.mic_off : Icons.mic,
                  color: _muted ? Colors.redAccent : Colors.white24,
                  onPressed: _onToggleMute,
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  isLarge: true,
                  onPressed: () => Navigator.pop(context),
                ),
                _buildControlButton(
                  icon: _showDialPad ? Icons.keyboard_hide : Icons.dialpad,
                  color: _showDialPad ? const Color(0xFFBEF263) : Colors.white24,
                  onPressed: () {
                    setState(() {
                      _showDialPad = !_showDialPad;
                    });
                  },
                ),
                if (!widget.isAudioOnly)
                  _buildControlButton(
                    icon: _videoOff ? Icons.videocam_off : Icons.videocam,
                    color: _videoOff ? Colors.redAccent : Colors.white24,
                    onPressed: _onToggleVideo,
                  ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildAudioCallUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFBEF263).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBEF263), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFBEF263).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            size: 80,
            color: Color(0xFFBEF263),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          "AUDIO CALL",
          style: TextStyle(
            color: Color(0xFFBEF263),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        if (_remoteUid == null) ...[
          const SizedBox(height: 20),
          _buildWaitingState(),
        ],
      ],
    );
  }

  Widget _buildDialPad() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => setState(() => _showDialPad = false),
              ),
            ),
            const Spacer(),
            Text(
              _dialedNumbers,
              style: const TextStyle(
                color: Color(0xFFBEF263),
                fontSize: 48,
                fontWeight: FontWeight.w300,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              flex: 4,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1,
                children: [
                  for (var i = 1; i <= 9; i++) _buildDialButton(i.toString()),
                  _buildDialButton("*"),
                  _buildDialButton("0"),
                  _buildDialButton("#"),
                ],
              ),
            ),
            if (_dialedNumbers.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _dialedNumbers = ""),
                child: const Text(
                  "CLEAR",
                  style: TextStyle(color: Colors.redAccent, letterSpacing: 2),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialButton(String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _dialedNumbers += label;
        });
        // Optional: play sound or send DTMF
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33BEF263), width: 1),
          color: const Color(0xFF1B2210).withOpacity(0.5),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      iconSize: isLarge ? 40 : 28,
      padding: EdgeInsets.all(isLarge ? 12 : 8),
      constraints: const BoxConstraints(),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

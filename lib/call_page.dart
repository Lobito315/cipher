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
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 28),
                    onPressed: () => setState(() => _showDialPad = false),
                  ),
                ),
              ),
              
              const Spacer(flex: 1),
              
              // Dialed Numbers Display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _dialedNumbers.isEmpty ? " " : _dialedNumbers,
                  style: const TextStyle(
                    color: Color(0xFFBEF263),
                    fontSize: 42,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Keypad Grid with constraints
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    children: [
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                        children: [
                          for (var i = 1; i <= 9; i++) _buildDialButton(i.toString()),
                          _buildDialButton("*"),
                          _buildDialButton("0"),
                          _buildDialButton("#"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Clear Button
              if (_dialedNumbers.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _dialedNumbers = ""),
                  icon: const Icon(Icons.backspace_outlined, color: Colors.white54, size: 16),
                  label: const Text(
                    "CLEAR",
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2),
                  ),
                ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDialActionButton(
          icon: Icons.call,
          color: const Color(0xFFBEF263),
          textColor: const Color(0xFF1B2210),
          label: "CALL",
          onPressed: () {
            // Logic for a new call or UI feedback
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Initiating call..."),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        _buildDialActionButton(
          icon: Icons.call_end,
          color: Colors.redAccent,
          textColor: Colors.white,
          label: "END",
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDialActionButton({
    required IconData icon,
    required Color color,
    required Color textColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialButton(String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _dialedNumbers += label;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22BEF263), width: 1),
            color: const Color(0xFFBEF263).withOpacity(0.05),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w300,
              ),
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
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: onPressed,
        iconSize: isLarge ? 40 : 28,
        padding: EdgeInsets.all(isLarge ? 12 : 8),
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLarge ? 20 : 15),
          ),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/call_provider.dart';
import 'services/call_service.dart';

// Conditional import: web gets the stub, native gets the real Agora service
import 'services/video_call_service.dart'
    if (dart.library.html) 'services/video_call_service_web.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final String remoteUserName;
  final String remoteUserId;   // needed to send CALL_ENDED signal
  final bool isAudioOnly;

  const CallPage({
    super.key,
    required this.channelName,
    required this.remoteUserName,
    required this.remoteUserId,
    this.isAudioOnly = false,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage>
    with SingleTickerProviderStateMixin {
  bool _muted = false;
  bool _showDialPad = false;
  bool _connected = false;
  String _statusText = 'Connecting...';
  String _dialedNumbers = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _videoCallService = VideoCallService();
  final _callService = CallService();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Defer to after first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCall();
      // Listen for the remote party hanging up or rejecting.
      final callProvider = context.read<CallProvider>();
      callProvider.onRemoteCallEnded = _onRemoteHangUp;
      callProvider.onCallRejected = _onCallRejected;
    });
  }

  Future<void> _initCall() async {
    if (kIsWeb) {
      // Web: Agora is not supported. Show "ringing" then "connected" UI.
      // setState is safe here because we're past the first frame.
      if (mounted) setState(() => _statusText = 'Ringing...');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _connected = true;
          _statusText = 'Connected';
        });
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
      return;
    }

    // Native: use Agora
    try {
      await _videoCallService.initialize();
      await _videoCallService.joinChannel(widget.channelName, 0);
      if (mounted) {
        setState(() {
          _connected = true;
          _statusText = 'Connected';
        });
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    } catch (e) {
      debugPrint('Call init error: $e');
      if (mounted) setState(() => _statusText = 'Connection failed');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Unregister callback so a stale reference doesn't linger.
    if (mounted) {
      try {
        final callProvider = context.read<CallProvider>();
        callProvider.onRemoteCallEnded = null;
        callProvider.onCallRejected = null;
      } catch (_) {}
    }
    if (!kIsWeb) {
      _videoCallService.leaveChannel();
      _videoCallService.dispose();
    }
    super.dispose();
  }

  /// Called when the remote party sends CALL_ENDED.
  void _onRemoteHangUp() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The other party ended the call.'),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF1B2210),
      ),
    );
    Navigator.of(context).pop();
  }

  /// Called when the remote party sends CALL_REJECTED.
  void _onCallRejected() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The other party declined the call.'),
        duration: Duration(seconds: 3),
        backgroundColor: Colors.redAccent,
      ),
    );
    Navigator.of(context).pop();
  }

  /// Ends the call locally and notifies the remote party.
  Future<void> _endCall() async {
    await _callService.endCall(
      receiverId: widget.remoteUserId,
      channelId: widget.channelName,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _onToggleMute() {
    setState(() => _muted = !_muted);
    // Agora mute handled inside VideoCallService; guarded at runtime
    try {
      if (!kIsWeb) _videoCallService.engine?.muteLocalAudioStream(_muted);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C07),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    const Color(0xFFBEF263).withOpacity(0.05),
                    const Color(0xFF0A0C07),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Center(child: _buildMainUI()),

          // Header
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.lock, color: Color(0xFFBEF263), size: 14),
                  SizedBox(width: 4),
                  Text('End-to-End Encrypted',
                      style: TextStyle(color: Color(0xFFBEF263), fontSize: 12)),
                ]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _connected ? '🔴  Live' : '...',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: _buildControls()),

          // Dial pad
          if (_showDialPad) Positioned.fill(child: _buildDialPad()),
        ],
      ),
    );
  }

  Widget _buildMainUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing avatar
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _connected ? 1.0 : _pulseAnimation.value,
            child: child,
          ),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFBEF263).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFBEF263)
                    .withOpacity(_connected ? 0.7 : 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBEF263)
                      .withOpacity(_connected ? 0.3 : 0.1),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child:
                const Icon(Icons.person, size: 80, color: Color(0xFFBEF263)),
          ),
        ),
        const SizedBox(height: 32),

        // Name
        Text(
          widget.remoteUserName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFBEF263).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: const Color(0xFFBEF263).withOpacity(0.3)),
          ),
          child: Text(
            widget.isAudioOnly ? 'AUDIO CALL' : 'VIDEO CALL',
            style: const TextStyle(
              color: Color(0xFFBEF263),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Status
        if (!_connected)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFBEF263).withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 10),
              Text(_statusText,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 14)),
            ],
          )
        else
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFFBEF263), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('Connected',
                style: TextStyle(
                    color: Color(0xFFBEF263),
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),

        // Web notice
        if (kIsWeb) ...[
          const SizedBox(height: 28),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 48),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Real-time audio requires the Cipher mobile app. This is a web preview.',
                    style: TextStyle(color: Colors.amber, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2210).withOpacity(0.88),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0x33BEF263)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCtrlBtn(
                icon: _muted ? Icons.mic_off : Icons.mic,
                label: _muted ? 'Unmute' : 'Mute',
                color: _muted ? Colors.redAccent : Colors.white24,
                onTap: _onToggleMute,
              ),
              Column(children: [
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 4)
                      ],
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 30),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('End',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
              _buildCtrlBtn(
                icon: _showDialPad
                    ? Icons.keyboard_hide
                    : Icons.dialpad,
                label: 'Keypad',
                color:
                    _showDialPad ? const Color(0xFFBEF263) : Colors.white24,
                onTap: () =>
                    setState(() => _showDialPad = !_showDialPad),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCtrlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
      const SizedBox(height: 8),
      Text(label,
          style: const TextStyle(color: Colors.white54, fontSize: 11)),
    ]);
  }

  Widget _buildDialPad() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                padding: const EdgeInsets.all(20),
                icon: const Icon(Icons.close,
                    color: Colors.white70, size: 28),
                onPressed: () => setState(() => _showDialPad = false),
              ),
            ),
            const Spacer(),
            Text(
              _dialedNumbers.isEmpty ? ' ' : _dialedNumbers,
              style: const TextStyle(
                  color: Color(0xFFBEF263),
                  fontSize: 42,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    for (var i = 1; i <= 9; i++)
                      _buildKey(i.toString()),
                    _buildKey('*'),
                    _buildKey('0'),
                    _buildKey('#'),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => setState(() => _dialedNumbers += label),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFBEF263).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22BEF263)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w300)),
        ),
      ),
    );
  }
}

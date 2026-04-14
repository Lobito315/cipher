import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import '../call_page.dart';
import '../main.dart';

class IncomingCallOverlay extends StatelessWidget {
  const IncomingCallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        if (!callProvider.isIncomingCall) return const SizedBox.shrink();

        final isAudio = callProvider.isAudioOnly;

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Blur background
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: const Color(0xFF0A0C07).withOpacity(0.8),
                ),
              ),
              
              // Call Content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Avatar/Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBEF263), width: 2),
                      ),
                      child: Icon(
                        isAudio ? Icons.call : Icons.person,
                        size: 60,
                        color: const Color(0xFFBEF263),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      callProvider.callerName ?? "Unknown Caller",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAudio ? "INCOMING AUDIO CALL" : "INCOMING VIDEO CALL",
                      style: const TextStyle(
                        color: Color(0xFFBEF263),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    
                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCallButton(
                            icon: Icons.close,
                            color: Colors.redAccent,
                            label: "Decline",
                            onTap: () => callProvider.rejectCall(),
                          ),
                          _buildCallButton(
                            icon: isAudio ? Icons.call : Icons.videocam,
                            color: const Color(0xFFBEF263),
                            label: "Accept",
                            iconColor: const Color(0xFF1B2210),
                            onTap: () {
                              callProvider.acceptCall(context, (channel, name, isAudioOnly) {
                                // Use the global navigator key because this overlay
                                // is rendered as a sibling of the Navigator (in
                                // MaterialApp.builder), so context-based navigation
                                // cannot reach the Navigator via ancestor lookup.
                                MyApp.navigatorKey.currentState?.push(
                                  MaterialPageRoute(
                                    builder: (_) => CallPage(
                                      channelName: channel,
                                      remoteUserName: name,
                                      isAudioOnly: isAudioOnly,
                                    ),
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

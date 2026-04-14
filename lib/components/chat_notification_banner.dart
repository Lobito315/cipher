import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_notification_provider.dart';
import '../chat_detail_page.dart';
import '../main.dart';

/// Animated top banner that appears when a new chat message arrives.
/// Tapping it navigates to the conversation; it auto-dismisses after 5s.
class ChatNotificationBanner extends StatefulWidget {
  const ChatNotificationBanner({super.key});

  @override
  State<ChatNotificationBanner> createState() => _ChatNotificationBannerState();
}

class _ChatNotificationBannerState extends State<ChatNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TickerFuture _hide() => _controller.reverse();

  void _dismiss(ChatNotificationProvider provider) {
    _hide().then((_) => provider.dismiss());
  }

  void _openChat(ChatNotification notification, ChatNotificationProvider provider) {
    _dismiss(provider);
    MyApp.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          receiverId: notification.senderId,
          receiverName: notification.senderName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatNotificationProvider>(
      builder: (context, provider, _) {
        final notification = provider.pending;

        if (notification != null) {
          // New notification arrived — play enter animation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controller.status != AnimationStatus.forward &&
                _controller.status != AnimationStatus.completed) {
              _controller.forward();
              // Auto-dismiss after 5 seconds
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted && provider.pending != null) {
                  _dismiss(provider);
                }
              });
            }
          });
        }

        if (notification == null && _controller.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _BannerCard(
                  notification: notification,
                  onTap: notification != null
                      ? () => _openChat(notification, provider)
                      : null,
                  onDismiss: () => _dismiss(provider),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ChatNotification? notification;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final name = notification?.senderName ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2A12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x33BEF263), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBEF263).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFBEF263).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFBEF263).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFFBEF263),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock,
                        color: Color(0xFFBEF263),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'CIPHER',
                        style: TextStyle(
                          color: Color(0xFFBEF263),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    '🔒 Encrypted message',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Dismiss button
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: const Color(0xFFBEF263).withOpacity(0.4),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ChatDetailPage extends StatelessWidget {
  const ChatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210), // dark:bg-background-dark
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2210).withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF1F5F9)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEF263).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFBEF263).withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      "https://lh3.googleusercontent.com/aida-public/AB6AXuBFU5v_BF5cGe5QqCfJuY0TEd31lPYxYos4NRgHUtt5z6a_fu8INIfAd1o7ED4NoX4L_ognKVYvFxlY3eMxf5G4xaCTX96sBo2_qg50Ld27FjQbxzZg95445sKNKVYcZk3dfoCMa0j1Hc21sWEpl2Fz0wLIHk0D2_zCJB3j0Ueln4UboA68Va4nqg0KmIoSt1jnj68iOgLaU7_Z35F9B1tEdXCEeLPXvuf2XdcCQrzNuLFmK-_zhsU17Cj0QEvaY-wyegTtN_BGB8w",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBEF263),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1B2210),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.verified,
                        size: 10,
                        color: Color(0xFF1B2210),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cipher Alpha-7',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF1F5F9),
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBEF263),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ACTIVE PROTOCOL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBEF263),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFF1F5F9)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFBEF263).withOpacity(0.1),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Quantum-Safe notification
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBEF263).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBEF263).withOpacity(0.1),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.enhanced_encryption,
                        size: 14,
                        color: Color(0xFFBEF263),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'QUANTUM-SAFE ENCRYPTION ENABLED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBEF263),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                // Timestamp
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                // Received Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.terminal,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                              border: Border(
                                left: BorderSide(
                                  color: Color(0xFF38BDF8),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: const Text(
                              'The vault assets have been relocated. Terminal 4 is now offline.',
                              style: TextStyle(
                                color: Color(0xFFF1F5F9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 4.0),
                            child: Text(
                              '09:41 AM',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 64), // Push gap from right
                  ],
                ),
                const SizedBox(height: 24),

                // Sent Message
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 64), // Push gap from left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFBEF263),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: const Text(
                              'Copy that. Initiating the #38BDF8 sequence for the secondary backup.',
                              style: TextStyle(
                                color: Color(0xFF1B2210),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Delivered',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 12,
                                color: Color(0xFFBEF263),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Security Alert
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 14,
                          color: Colors.red[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SECURITY ALERT: SCREEN RECORDING BLOCKED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[400],
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Received Message with blurred image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.terminal,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E293B),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                              border: Border(
                                left: BorderSide(
                                  color: Color(0xFF38BDF8),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Blurred Image container
                                Container(
                                  width: double.infinity,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                    ),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        "https://lh3.googleusercontent.com/aida-public/AB6AXuBCo61SJvsocYEdstACLo06GKRZNfV8pc0BWVI9UEaiSVhaBXSjSM-v4PyANl0uX0IO-KO2H7AB0BJ-YW_o1pCr2gKjQ7kVBo1gWjpfurHWf1zybyU4ArCfpK2SrhZv6WEKLweWWaKYIy0NinCv9zPB8ujGv2DPVAS10Jb2jLeu07nH0CTSRkSk0hW3u07cXAVrBDsjI5rUKpN2a0o7J-ytc-bWggBMG_3KApZMf2GYZuhBf0KgGfIvPkzNVg_j8tVMRFcEyacOXvA",
                                        fit: BoxFit.cover,
                                      ),
                                      // Local blur effect (alternative to ImageFilter.blur to avoid complex imports if not needed, or just overlay black)
                                      Container(
                                        color: Colors.black.withOpacity(0.6),
                                        child: Center(
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: const Color(
                                              0xFFBEF263,
                                            ).withOpacity(0.8),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Encrypted blueprint attached. Self-destruct timer: 30s.',
                                  style: TextStyle(
                                    color: Color(0xFFF1F5F9),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Row(
                              children: [
                                const Text(
                                  '09:44 AM',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 12,
                                      color: Color(0xFF38BDF8),
                                    ),
                                    const SizedBox(width: 2),
                                    const Text(
                                      '28s',
                                      style: TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40), // Push gap from right
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          // Bottom Input Area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2210),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFBEF263).withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A), // slate-900 approx
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBEF263).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {},
                            ),
                            Expanded(
                              child: TextField(
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Type a secure message...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: 4,
                                minLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.mic,
                                color: Color(0xFF64748B),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBEF263),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFBEF263).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color(0xFF1B2210),
                          size: 20,
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer Status
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: 0.4,
                      child: Row(
                        children: [
                          Icon(
                            Icons.no_photography,
                            size: 10,
                            color: Color(0xFFF1F5F9),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'ANTI-CAPTURE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Opacity(
                      opacity: 0.4,
                      child: Row(
                        children: [
                          Icon(
                            Icons.vpn_key,
                            size: 10,
                            color: Color(0xFFF1F5F9),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'VAULT-MODE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

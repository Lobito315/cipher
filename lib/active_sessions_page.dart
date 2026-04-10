import 'package:flutter/material.dart';

class ActiveSessionsPage extends StatelessWidget {
  const ActiveSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2210),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Active Sessions', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSessionCard(
            deviceName: 'Windows Desktop (Current)',
            location: 'Madrid, Spain',
            lastActive: 'Active now',
            isCurrent: true,
          ),
          const SizedBox(height: 12),
          _buildSessionCard(
            deviceName: 'iPhone 15 Pro',
            location: 'Madrid, Spain',
            lastActive: '2 days ago',
            isCurrent: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard({
    required String deviceName,
    required String location,
    required String lastActive,
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3319),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A4823)),
      ),
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.computer : Icons.smartphone,
            color: isCurrent ? const Color(0xFFBEF263) : Colors.white70,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$location • $lastActive',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () {},
              child: const Text('Revoke', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
    );
  }
}

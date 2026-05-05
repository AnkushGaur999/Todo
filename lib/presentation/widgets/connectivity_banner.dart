import 'package:flutter/material.dart';

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final bool isSyncing;
  final String? syncMessage;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    required this.isSyncing,
    this.syncMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isSyncing) {
      return _buildBanner(
        color: Colors.blue.shade700,
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        message: 'Syncing changes…',
      );
    }

    if (!isOnline) {
      return _buildBanner(
        color: Colors.orange.shade700,
        icon: const Icon(Icons.wifi_off, size: 16, color: Colors.white),
        message: 'You\'re offline — changes will sync when reconnected',
      );
    }

    if (syncMessage != null) {
      return _buildBanner(
        color: Colors.green.shade700,
        icon: const Icon(Icons.check_circle_outline,
            size: 16, color: Colors.white),
        message: syncMessage!,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner({
    required Color color,
    required Widget icon,
    required String message,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

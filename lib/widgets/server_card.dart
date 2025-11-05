import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/server_model.dart';
import '../providers/ping_provider.dart';
import '../screens/server_history_screen.dart';
import '../screens/deep_scan_screen.dart';

class ServerCard extends StatelessWidget {
  final ServerModel server;
  final VoidCallback onRemove;
  final VoidCallback onToggleMonitoring;
  final VoidCallback onManualPing;

  const ServerCard({
    super.key,
    required this.server,
    required this.onRemove,
    required this.onToggleMonitoring,
    required this.onManualPing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        server.ip,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onManualPing,
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Ping manual',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServerHistoryScreen(serverId: server.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 20),
                      tooltip: 'Ver historial',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeepScanScreen(
                              serverId: server.id,
                              serverName: server.name,
                              serverIp: server.ip,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.security, size: 20),
                      tooltip: 'Escaneo profundo',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    Switch(
                      value: server.isMonitoring,
                      onChanged: (_) => onToggleMonitoring(),
                      activeColor: const Color(0xFF0078D4),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      tooltip: 'Eliminar',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (server.responseTime != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tiempo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${server.responseTime}ms',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Última verificación',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getLastCheckedText(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (server.lastChecked == null) {
      return Colors.grey;
    }
    return server.isOnline ? Colors.green : Colors.red;
  }

  String _getStatusText() {
    if (server.lastChecked == null) {
      return 'Sin verificar';
    }
    return server.isOnline ? 'En línea' : 'Fuera de línea';
  }

  String _getLastCheckedText() {
    if (server.lastChecked == null) {
      return 'Nunca';
    }
    
    final now = DateTime.now();
    final difference = now.difference(server.lastChecked!);
    
    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}
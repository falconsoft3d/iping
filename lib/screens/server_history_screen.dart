import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/server_model.dart';
import '../providers/ping_provider.dart';

class ServerHistoryScreen extends StatefulWidget {
  final String serverId;

  const ServerHistoryScreen({
    Key? key,
    required this.serverId,
  }) : super(key: key);

  @override
  State<ServerHistoryScreen> createState() => _ServerHistoryScreenState();
}

class _ServerHistoryScreenState extends State<ServerHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PingProvider>(
      builder: (context, pingProvider, child) {
        final server = pingProvider.servers.firstWhere(
          (s) => s.id == widget.serverId,
          orElse: () => throw Exception('Servidor no encontrado'),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('Historial de ${server.name}'),
            backgroundColor: const Color(0xFF0078D4),
            foregroundColor: Colors.white,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  pingProvider.manualPing(server.id);
                },
                tooltip: 'Ping manual',
              ),
            ],
          ),
          body: Column(
            children: [
              // Header con información del servidor
              Container(
                width: double.infinity,
                color: Colors.grey[100],
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          color: const Color(0xFF0078D4),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          server.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IP: ${server.ip}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: server.isOnline ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          server.isOnline ? 'En línea' : 'Fuera de línea',
                          style: TextStyle(
                            color: server.isOnline ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (server.responseTime != null) ...[
                          const SizedBox(width: 16),
                          Text(
                            '${server.responseTime}ms',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitoreando: ${server.isMonitoring ? "Sí" : "No"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: server.isMonitoring ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Estadísticas
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      server.history.length.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'En línea',
                      server.history.where((h) => h.isOnline).length.toString(),
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Fuera de línea',
                      server.history.where((h) => !h.isOnline).length.toString(),
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Promedio',
                      _getAverageResponseTime(server),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Lista del historial
              Expanded(
                child: server.history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay historial disponible',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'El historial se generará automáticamente\ncuando el servidor esté siendo monitoreado',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                pingProvider.manualPing(server.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0078D4),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Hacer ping ahora'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: server.history.length,
                        itemBuilder: (context, index) {
                          final entry = server.history[server.history.length - 1 - index]; // Más reciente primero
                          return _buildHistoryItem(entry, index == 0); // Marcar el más reciente
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getAverageResponseTime(ServerModel server) {
    final onlineEntries = server.history.where((h) => h.isOnline && h.responseTime != null);
    if (onlineEntries.isEmpty) return '-';
    
    final average = onlineEntries.map((e) => e.responseTime!).reduce((a, b) => a + b) / onlineEntries.length;
    return '${average.round()}ms';
  }

  Widget _buildHistoryItem(PingHistoryEntry entry, bool isLatest) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: isLatest ? Colors.blue[50] : null,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
          left: isLatest ? BorderSide(
            color: const Color(0xFF0078D4),
            width: 4,
          ) : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: entry.isOnline ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              border: isLatest ? Border.all(
                color: Colors.white,
                width: 2,
              ) : null,
              boxShadow: isLatest ? [
                BoxShadow(
                  color: entry.isOnline ? Colors.green[300]! : Colors.red[300]!,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.isOnline ? 'En línea' : 'Fuera de línea',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: entry.isOnline ? Colors.green : Colors.red,
                          ),
                        ),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0078D4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'NUEVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeFormat.format(entry.timestamp),
                      style: TextStyle(
                        fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
                        color: isLatest ? const Color(0xFF0078D4) : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.responseTime != null 
                            ? 'Tiempo de respuesta: ${entry.responseTime}ms'
                            : entry.errorMessage ?? 'Sin respuesta',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLatest ? Colors.grey[700] : Colors.grey[600],
                        ),
                      ),
                    ),
                    Text(
                      dateFormat.format(entry.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLatest ? Colors.grey[600] : Colors.grey[500],
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
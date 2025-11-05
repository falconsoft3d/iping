import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ping_provider.dart';
import '../widgets/server_card.dart';
import '../widgets/add_server_dialog.dart';
import 'statistics_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.network_ping, size: 24),
            SizedBox(width: 8),
            Text('iPing - Network Monitor'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StatisticsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadísticas',
          ),
          Consumer<PingProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : provider.refreshAll,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Actualizar todos',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<PingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.servers.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.servers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.network_ping,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay servidores configurados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Presiona el botón + para agregar un servidor',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.servers.length,
            itemBuilder: (context, index) {
              final server = provider.servers[index];
              return ServerCard(
                server: server,
                onRemove: () => _showRemoveDialog(context, provider, server.id),
                onToggleMonitoring: () => provider.toggleMonitoring(server.id),
                onManualPing: () => provider.manualPing(server.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServerDialog(context),
        backgroundColor: const Color(0xFF0078D4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddServerDialog(),
    );
  }

  void _showRemoveDialog(BuildContext context, PingProvider provider, String serverId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servidor'),
        content: const Text('¿Estás seguro de que quieres eliminar este servidor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeServer(serverId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
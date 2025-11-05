import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _statistics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _dbHelper.getServerStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics.isEmpty
              ? const Center(
                  child: Text(
                    'No hay estadísticas disponibles',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _statistics.length,
                  itemBuilder: (context, index) {
                    final stat = _statistics[index];
                    return _buildStatisticsCard(stat);
                  },
                ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stat) {
    final isOnline = stat['is_online'] == 1;
    final pingCount = stat['ping_count'] ?? 0;
    final successfulPings = stat['successful_pings'] ?? 0;
    final failedPings = stat['failed_pings'] ?? 0;
    final avgResponseTime = stat['avg_response_time'];
    final lastChecked = stat['last_checked'] != null
        ? DateTime.parse(stat['last_checked'])
        : null;

    final successRate = pingCount > 0 ? (successfulPings / pingCount * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre y estado
            Row(
              children: [
                Icon(
                  isOnline ? Icons.check_circle : Icons.error,
                  color: isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat['name'] ?? 'Servidor',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              stat['ip'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Estadísticas en grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Pings',
                    pingCount.toString(),
                    Icons.timeline,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Exitosos',
                    successfulPings.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Fallidos',
                    failedPings.toString(),
                    Icons.error_outline,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tasa de Éxito',
                    '${successRate.toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            if (avgResponseTime != null) ...[
              const SizedBox(height: 12),
              _buildStatItem(
                'Tiempo Promedio',
                '${avgResponseTime.toStringAsFixed(0)} ms',
                Icons.speed,
                Colors.purple,
                fullWidth: true,
              ),
            ],

            if (lastChecked != null) ...[
              const SizedBox(height: 16),
              Text(
                'Última verificación: ${_formatDateTime(lastChecked)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],

            // Barra de progreso de la tasa de éxito
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Confiabilidad: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: successRate / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      successRate >= 95 ? Colors.green :
                      successRate >= 80 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${successRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    {bool fullWidth = false}
  ) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else {
      return 'hace ${difference.inDays} días';
    }
  }
}
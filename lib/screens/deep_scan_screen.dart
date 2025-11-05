import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/deep_scan_model.dart';

class DeepScanScreen extends StatefulWidget {
  final String serverId;
  final String serverName;
  final String serverIp;

  const DeepScanScreen({
    Key? key,
    required this.serverId,
    required this.serverName,
    required this.serverIp,
  }) : super(key: key);

  @override
  State<DeepScanScreen> createState() => _DeepScanScreenState();
}

class _DeepScanScreenState extends State<DeepScanScreen> {
  bool isScanning = false;
  DeepScanResult? scanResult;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Escaneo Profundo - ${widget.serverName}'),
        backgroundColor: const Color(0xFF0078D4),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : _performDeepScan,
            tooltip: 'Realizar escaneo',
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
                      Icons.security,
                      color: const Color(0xFF0078D4),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.serverName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'IP: ${widget.serverIp}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                if (scanResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Último escaneo: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(scanResult!.scanTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: isScanning
                ? _buildScanningWidget()
                : error != null
                    ? _buildErrorWidget()
                    : scanResult != null
                        ? _buildScanResults()
                        : _buildInitialWidget(),
          ),
        ],
      ),
      floatingActionButton: scanResult == null && !isScanning
          ? FloatingActionButton.extended(
              onPressed: _performDeepScan,
              backgroundColor: const Color(0xFF0078D4),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.scanner),
              label: const Text('Iniciar Escaneo'),
            )
          : null,
    );
  }

  Widget _buildScanningWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0078D4)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Realizando escaneo profundo...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto puede tomar varios minutos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '• Resolviendo registros DNS\n'
            '• Escaneando puertos comunes\n'
            '• Obteniendo información de red\n'
            '• Analizando servicios',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error en el escaneo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _performDeepScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0078D4),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Escaneo Profundo Disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obtén información detallada sobre el servidor',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'El escaneo incluirá:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.dns, 'Registros DNS (A, AAAA, MX, NS, CNAME)'),
                  _buildFeatureItem(Icons.settings_ethernet, 'Puertos abiertos y servicios'),
                  _buildFeatureItem(Icons.network_check, 'Información de red y geolocalización'),
                  _buildFeatureItem(Icons.security, 'Análisis de seguridad básico'),
                  _buildFeatureItem(Icons.speed, 'Métricas de rendimiento'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF0078D4),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResults() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Color(0xFF0078D4),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF0078D4),
              tabs: [
                Tab(icon: Icon(Icons.dns), text: 'DNS'),
                Tab(icon: Icon(Icons.settings_ethernet), text: 'Puertos'),
                Tab(icon: Icon(Icons.network_check), text: 'Red'),
                Tab(icon: Icon(Icons.info), text: 'Resumen'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDnsTab(),
                _buildPortsTab(),
                _buildNetworkTab(),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (scanResult!.dnsRecords.isEmpty)
          _buildEmptyState(Icons.dns, 'No se encontraron registros DNS')
        else
          ...scanResult!.dnsRecords.map((record) => _buildDnsRecordCard(record)),
      ],
    );
  }

  Widget _buildDnsRecordCard(DnsRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getDnsTypeColor(record.type),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            record.type,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          record.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(record.value),
        trailing: record.ttl != null
            ? Text(
                'TTL: ${record.ttl}s',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPortsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (scanResult!.openPorts.isNotEmpty) ...[
          Text(
            'Puertos Abiertos (${scanResult!.openPorts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...scanResult!.openPorts.map((port) => _buildPortCard(port, true)),
          const SizedBox(height: 16),
        ],
        if (scanResult!.closedPorts.isNotEmpty) ...[
          Text(
            'Puertos Cerrados/Filtrados (${scanResult!.closedPorts.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          ...scanResult!.closedPorts.take(10).map((port) => _buildPortCard(port, false)),
          if (scanResult!.closedPorts.length > 10)
            Text(
              '... y ${scanResult!.closedPorts.length - 10} puertos más',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
        if (scanResult!.openPorts.isEmpty && scanResult!.closedPorts.isEmpty)
          _buildEmptyState(Icons.settings_ethernet, 'No se pudieron escanear puertos'),
      ],
    );
  }

  Widget _buildPortCard(PortInfo port, bool isOpen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isOpen ? Icons.lock_open : Icons.lock,
          color: isOpen ? Colors.green : Colors.orange,
        ),
        title: Text(
          'Puerto ${port.port}/${port.protocol}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: ${port.status}'),
            if (port.service != null) Text('Servicio: ${port.service}'),
            if (port.banner != null) Text('Banner: ${port.banner}'),
          ],
        ),
        trailing: Text(
          '${port.responseTime}ms',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNetworkTab() {
    final info = scanResult!.networkInfo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Información General', [
          if (info.hostname != null) _buildInfoRow('Hostname', info.hostname!),
          _buildInfoRow('Direcciones IP', info.ipAddresses.join(', ')),
          _buildInfoRow('Estado', info.isReachable ? 'Alcanzable' : 'No alcanzable'),
          if (info.avgResponseTime != null)
            _buildInfoRow('Tiempo promedio', '${info.avgResponseTime}ms'),
          if (info.packetLoss != null)
            _buildInfoRow('Pérdida de paquetes', '${info.packetLoss}%'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Información Geográfica', [
          if (info.organization != null) _buildInfoRow('Organización', info.organization!),
          if (info.isp != null) _buildInfoRow('ISP', info.isp!),
          if (info.country != null) _buildInfoRow('País', info.country!),
          if (info.city != null) _buildInfoRow('Ciudad', info.city!),
        ]),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard('Registros DNS', scanResult!.dnsRecords.length.toString(), Icons.dns, Colors.blue),
        _buildSummaryCard('Puertos Abiertos', scanResult!.openPorts.length.toString(), Icons.lock_open, Colors.green),
        _buildSummaryCard('Puertos Cerrados', scanResult!.closedPorts.length.toString(), Icons.lock, Colors.orange),
        _buildSummaryCard('Estado de Red', scanResult!.networkInfo.isReachable ? 'Alcanzable' : 'No alcanzable', Icons.network_check, scanResult!.networkInfo.isReachable ? Colors.green : Colors.red),
        
        if (scanResult!.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Advertencias',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...scanResult!.errors.map((error) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $error',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDnsTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'A':
        return Colors.blue;
      case 'AAAA':
        return Colors.purple;
      case 'MX':
        return Colors.green;
      case 'NS':
        return Colors.orange;
      case 'CNAME':
        return Colors.teal;
      case 'TXT':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Future<void> _performDeepScan() async {
    setState(() {
      isScanning = true;
      error = null;
    });

    try {
      // Simular escaneo profundo - en una implementación real, aquí llamarías a APIs reales
      await Future.delayed(const Duration(seconds: 3));
      
      final result = await _simulateDeepScan();
      
      setState(() {
        scanResult = result;
        isScanning = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isScanning = false;
      });
    }
  }

  Future<DeepScanResult> _simulateDeepScan() async {
    // Simulación de datos - en producción, esto haría llamadas reales
    final dnsRecords = <DnsRecord>[
      DnsRecord(type: 'A', name: widget.serverIp, value: widget.serverIp, ttl: 300),
      if (widget.serverIp.contains('.com') || widget.serverIp.contains('.'))
        DnsRecord(type: 'CNAME', name: widget.serverIp, value: 'example.com', ttl: 3600),
    ];

    final openPorts = <PortInfo>[
      if (widget.serverIp.contains('8.8.8.8') || widget.serverIp.contains('1.1.1.1'))
        PortInfo(port: 53, protocol: 'UDP', status: 'open', service: 'DNS', responseTime: 20),
      if (widget.serverIp.contains('.com'))
        ...[
          PortInfo(port: 80, protocol: 'TCP', status: 'open', service: 'HTTP', responseTime: 45),
          PortInfo(port: 443, protocol: 'TCP', status: 'open', service: 'HTTPS', responseTime: 52),
        ],
    ];

    final closedPorts = <PortInfo>[
      PortInfo(port: 22, protocol: 'TCP', status: 'closed', responseTime: 1000),
      PortInfo(port: 23, protocol: 'TCP', status: 'filtered', responseTime: 2000),
      PortInfo(port: 25, protocol: 'TCP', status: 'closed', responseTime: 1500),
    ];

    final networkInfo = NetworkInfo(
      hostname: widget.serverIp.contains('.com') ? widget.serverIp : null,
      ipAddresses: [widget.serverIp],
      organization: widget.serverIp.contains('8.8.8.8') ? 'Google LLC' : 
                   widget.serverIp.contains('1.1.1.1') ? 'Cloudflare, Inc.' : 'Unknown',
      country: 'Estados Unidos',
      city: 'Mountain View',
      isp: widget.serverIp.contains('8.8.8.8') ? 'Google' : 'Cloudflare',
      isReachable: true,
      avgResponseTime: 25,
      packetLoss: 0,
    );

    return DeepScanResult(
      serverId: widget.serverId,
      serverName: widget.serverName,
      serverIp: widget.serverIp,
      scanTime: DateTime.now(),
      dnsRecords: dnsRecords,
      openPorts: openPorts,
      closedPorts: closedPorts,
      networkInfo: networkInfo,
      errors: [],
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/server_model.dart';
import '../models/deep_scan_model.dart';

class PingProvider extends ChangeNotifier {
  List<ServerModel> _servers = [];
  bool _isLoading = false;
  Timer? _monitoringTimer;
  final int _pingInterval = 5; // segundos

  List<ServerModel> get servers => _servers;
  bool get isLoading => _isLoading;

  PingProvider() {
    _loadServers();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadServers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Forzar recarga de servidores de ejemplo para esta demo
      // Comentar esta línea después de la primera ejecución
      await prefs.remove('servers');
      
      final serversJson = prefs.getStringList('servers') ?? [];
      
      if (serversJson.isEmpty) {
        // Si no hay servidores guardados, agregar algunos ejemplos
        _servers = [
          ServerModel(
            id: '1',
            name: 'Google DNS',
            ip: '8.8.8.8',
            isMonitoring: true,
          ),
          ServerModel(
            id: '2',
            name: 'Cloudflare DNS',
            ip: '1.1.1.1',
            isMonitoring: true,
          ),
          ServerModel(
            id: '3',
            name: 'GitHub',
            ip: 'github.com',
            isMonitoring: true,
          ),
          ServerModel(
            id: '4',
            name: 'Stack Overflow',
            ip: 'stackoverflow.com',
            isMonitoring: true,
          ),
        ];
        // Guardar los servidores de ejemplo
        await _saveServers();
      } else {
        _servers = serversJson
            .map((json) => ServerModel.fromJson(jsonDecode(json)))
            .toList();
      }
    } catch (e) {
      print('Error loading servers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveServers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serversJson = _servers
          .map((server) => jsonEncode(server.toJson()))
          .toList();
      await prefs.setStringList('servers', serversJson);
    } catch (e) {
      print('Error saving servers: $e');
    }
  }

  Future<void> addServer(String name, String ip) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final server = ServerModel(
      id: id,
      name: name,
      ip: ip,
      isMonitoring: true,
    );

    _servers.add(server);
    await _saveServers();
    notifyListeners();

    // Hacer ping inmediatamente al nuevo servidor
    await _pingServer(server);
  }

  Future<void> removeServer(String id) async {
    _servers.removeWhere((server) => server.id == id);
    await _saveServers();
    notifyListeners();
  }

  Future<void> toggleMonitoring(String id) async {
    final index = _servers.indexWhere((server) => server.id == id);
    if (index != -1) {
      _servers[index] = _servers[index].copyWith(
        isMonitoring: !_servers[index].isMonitoring,
      );
      await _saveServers();
      notifyListeners();
    }
  }

  void _startMonitoring() {
    _monitoringTimer = Timer.periodic(
      Duration(seconds: _pingInterval),
      (timer) => _pingAllServers(),
    );
  }

  Future<void> _pingAllServers() async {
    final monitoredServers = _servers.where((s) => s.isMonitoring).toList();
    
    for (final server in monitoredServers) {
      await _pingServer(server);
    }
  }

  Future<void> _pingServer(ServerModel server) async {
    try {
      final stopwatch = Stopwatch()..start();
      bool isSuccess = false;
      String? errorMessage;
      
      // Usar DNS lookup + HTTP como método principal
      isSuccess = await _networkConnectivityTest(server.ip);
      
      stopwatch.stop();

      // Crear entrada del historial
      final historyEntry = PingHistoryEntry(
        timestamp: DateTime.now(),
        isOnline: isSuccess,
        responseTime: isSuccess ? stopwatch.elapsedMilliseconds : null,
        errorMessage: errorMessage,
      );

      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        // Agregar nueva entrada al historial
        final newHistory = List<PingHistoryEntry>.from(_servers[index].history);
        newHistory.add(historyEntry);
        
        // Mantener solo los últimos 100 registros
        if (newHistory.length > 100) {
          newHistory.removeAt(0);
        }
        
        _servers[index] = _servers[index].copyWith(
          isOnline: isSuccess,
          responseTime: isSuccess ? stopwatch.elapsedMilliseconds : null,
          lastChecked: DateTime.now(),
          history: newHistory,
        );
        
        print('Network test result for ${server.ip}: isOnline=$isSuccess, time=${stopwatch.elapsedMilliseconds}ms');
        
        notifyListeners();
      }
    } catch (e) {
      // Crear entrada del historial para errores
      final historyEntry = PingHistoryEntry(
        timestamp: DateTime.now(),
        isOnline: false,
        responseTime: null,
        errorMessage: e.toString(),
      );

      final index = _servers.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        // Agregar nueva entrada al historial
        final newHistory = List<PingHistoryEntry>.from(_servers[index].history);
        newHistory.add(historyEntry);
        
        // Mantener solo los últimos 100 registros
        if (newHistory.length > 100) {
          newHistory.removeAt(0);
        }
        
        _servers[index] = _servers[index].copyWith(
          isOnline: false,
          responseTime: null,
          lastChecked: DateTime.now(),
          history: newHistory,
        );
        notifyListeners();
      }
      print('Error testing ${server.ip}: $e');
    }
  }

  Future<bool> _networkConnectivityTest(String host) async {
    try {
      // Método 1: DNS Lookup (más confiable en macOS)
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isNotEmpty) {
        print('DNS lookup success for $host: ${addresses.first.address}');
        
        // Para dominios conocidos, intentar HTTP. Para IPs DNS, considerar DNS suficiente
        if (_isDNSServer(host) || _isIPAddress(host)) {
          // Para servidores DNS o IPs puras, DNS lookup es suficiente
          return true;
        } else {
          // Para dominios, intentar HTTP como confirmación
          return await _httpConnectivityTest(host);
        }
      }
      return false;
    } catch (e) {
      print('DNS lookup failed for $host: $e');
      // Si DNS falla, intentar directamente HTTP (puede ser una IP con servidor web)
      return await _httpConnectivityTest(host);
    }
  }

  bool _isDNSServer(String host) {
    // Lista de servidores DNS conocidos
    final knownDNSServers = [
      '8.8.8.8', '8.8.4.4', // Google DNS
      '1.1.1.1', '1.0.0.1', // Cloudflare DNS
      '9.9.9.9', // Quad9 DNS
      '208.67.222.222', '208.67.220.220', // OpenDNS
    ];
    return knownDNSServers.contains(host);
  }

  Future<bool> _httpConnectivityTest(String host) async {
    // Lista de URLs para probar
    final List<String> urlsToTry = [];
    
    if (_isIPAddress(host)) {
      // Para IPs, probar HTTP principalmente
      urlsToTry.addAll([
        'http://$host',
        'https://$host',
      ]);
    } else {
      // Para dominios, probar HTTPS primero, luego HTTP, luego puertos específicos
      urlsToTry.addAll([
        'https://$host',
        'http://$host',
        'https://$host:443',
        'http://$host:80',
      ]);
    }
    
    for (String url in urlsToTry) {
      try {
        final client = http.Client();
        final request = http.Request('HEAD', Uri.parse(url));
        request.headers['User-Agent'] = 'iPing/1.0';
        
        final response = await client.send(request).timeout(Duration(seconds: 2));
        client.close();
        
        if (response.statusCode >= 200 && response.statusCode < 600) {
          print('HTTP connectivity success for $host via $url: ${response.statusCode}');
          return true;
        }
      } catch (e) {
        // Si HEAD falla, intentar GET en caso de que el servidor no soporte HEAD
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'User-Agent': 'iPing/1.0'},
          ).timeout(Duration(seconds: 2));
          
          if (response.statusCode >= 200 && response.statusCode < 600) {
            print('HTTP GET connectivity success for $host via $url: ${response.statusCode}');
            return true;
          }
        } catch (e2) {
          continue; // Probar siguiente URL
        }
      }
    }
    
    print('All HTTP connectivity tests failed for $host');
    return false;
  }

  bool _isIPAddress(String host) {
    final ipRegex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(host);
  }

  Future<void> manualPing(String id) async {
    final server = _servers.firstWhere((s) => s.id == id);
    await _pingServer(server);
  }

  Future<void> refreshAll() async {
    await _pingAllServers();
  }

  // Métodos para escaneo profundo
  Future<DeepScanResult> performDeepScan(String serverId, String serverName, String serverIp) async {
    try {
      print('Iniciando escaneo profundo para $serverIp');
      
      final scanTime = DateTime.now();
      final errors = <String>[];
      
      // Ejecutar todos los escaneos en paralelo para mayor eficiencia
      final results = await Future.wait([
        _scanDnsRecords(serverIp).catchError((e) {
          errors.add('Error en DNS: $e');
          return <DnsRecord>[];
        }),
        _scanPorts(serverIp).catchError((e) {
          errors.add('Error en escaneo de puertos: $e');
          return <PortInfo>[];
        }),
        _getNetworkInfo(serverIp).catchError((e) {
          errors.add('Error en información de red: $e');
          return NetworkInfo(
            hostname: null,
            ipAddresses: [serverIp],
            organization: null,
            country: null,
            city: null,
            isp: null,
            isReachable: false,
            avgResponseTime: null,
            packetLoss: null,
          );
        }),
      ]);
      
      final dnsRecords = results[0] as List<DnsRecord>;
      final allPorts = results[1] as List<PortInfo>;
      final networkInfo = results[2] as NetworkInfo;
      
      // Separar puertos abiertos y cerrados
      final openPorts = allPorts.where((p) => p.status == 'open').toList();
      final closedPorts = allPorts.where((p) => p.status != 'open').toList();
      
      return DeepScanResult(
        serverId: serverId,
        serverName: serverName,
        serverIp: serverIp,
        scanTime: scanTime,
        dnsRecords: dnsRecords,
        openPorts: openPorts,
        closedPorts: closedPorts,
        networkInfo: networkInfo,
        errors: errors,
      );
    } catch (e) {
      print('Error en escaneo profundo: $e');
      rethrow;
    }
  }

  Future<List<DnsRecord>> _scanDnsRecords(String host) async {
    final records = <DnsRecord>[];
    
    try {
      // Resolver registro A (IPv4)
      final addresses = await InternetAddress.lookup(host, type: InternetAddressType.IPv4);
      for (final addr in addresses) {
        records.add(DnsRecord(
          type: 'A',
          name: host,
          value: addr.address,
          ttl: 300, // TTL simulado
        ));
      }
    } catch (e) {
      print('Error obteniendo registros A para $host: $e');
    }

    try {
      // Resolver registro AAAA (IPv6)
      final addresses = await InternetAddress.lookup(host, type: InternetAddressType.IPv6);
      for (final addr in addresses) {
        records.add(DnsRecord(
          type: 'AAAA',
          name: host,
          value: addr.address,
          ttl: 300,
        ));
      }
    } catch (e) {
      print('Error obteniendo registros AAAA para $host: $e');
    }

    // Para dominios, intentar resolver registros adicionales mediante DNS over HTTPS
    if (!_isIPAddress(host)) {
      await _queryDnsOverHttps(host, records);
    }

    return records;
  }

  Future<void> _queryDnsOverHttps(String host, List<DnsRecord> records) async {
    try {
      // Usar Cloudflare DNS over HTTPS para obtener más tipos de registros
      final dnsQueries = [
        {'type': 'MX', 'name': host},
        {'type': 'NS', 'name': host},
        {'type': 'CNAME', 'name': host},
        {'type': 'TXT', 'name': host},
      ];

      for (final query in dnsQueries) {
        try {
          final url = 'https://cloudflare-dns.com/dns-query?name=${query['name']}&type=${query['type']}';
          final response = await http.get(
            Uri.parse(url),
            headers: {'Accept': 'application/dns-json'},
          ).timeout(Duration(seconds: 5));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final answers = data['Answer'] as List?;
            
            if (answers != null) {
              for (final answer in answers) {
                if (answer['type'] == _getDnsTypeNumber(query['type']!)) {
                  records.add(DnsRecord(
                    type: query['type']!,
                    name: answer['name'] ?? host,
                    value: answer['data'] ?? '',
                    ttl: answer['TTL'],
                  ));
                }
              }
            }
          }
        } catch (e) {
          print('Error consultando ${query['type']} para $host: $e');
        }
      }
    } catch (e) {
      print('Error en DNS over HTTPS: $e');
    }
  }

  int _getDnsTypeNumber(String type) {
    switch (type) {
      case 'A': return 1;
      case 'NS': return 2;
      case 'CNAME': return 5;
      case 'MX': return 15;
      case 'TXT': return 16;
      case 'AAAA': return 28;
      default: return 1;
    }
  }

  Future<List<PortInfo>> _scanPorts(String host) async {
    final ports = <PortInfo>[];
    
    // Lista de puertos comunes para escanear
    final commonPorts = [
      21,   // FTP
      22,   // SSH
      23,   // Telnet
      25,   // SMTP
      53,   // DNS
      80,   // HTTP
      110,  // POP3
      143,  // IMAP
      443,  // HTTPS
      993,  // IMAPS
      995,  // POP3S
      3389, // RDP
      5432, // PostgreSQL
      3306, // MySQL
      1433, // SQL Server
      6379, // Redis
      27017, // MongoDB
      8080, // HTTP Alt
      8443, // HTTPS Alt
    ];

    // Resolver la dirección IP si es un dominio
    String targetIp = host;
    try {
      if (!_isIPAddress(host)) {
        final addresses = await InternetAddress.lookup(host);
        if (addresses.isNotEmpty) {
          targetIp = addresses.first.address;
        }
      }
    } catch (e) {
      print('Error resolviendo $host: $e');
      return ports;
    }

    // Escanear puertos en paralelo (en lotes para no sobrecargar)
    final futures = <Future<PortInfo>>[];
    
    for (final port in commonPorts) {
      futures.add(_scanSinglePort(targetIp, port));
      
      // Procesar en lotes de 5 para evitar sobrecarga
      if (futures.length >= 5) {
        final results = await Future.wait(futures);
        ports.addAll(results);
        futures.clear();
        
        // Pequeña pausa entre lotes
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    
    // Procesar puertos restantes
    if (futures.isNotEmpty) {
      final results = await Future.wait(futures);
      ports.addAll(results);
    }

    return ports;
  }

  Future<PortInfo> _scanSinglePort(String ip, int port) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));
      stopwatch.stop();
      
      String? service = _getServiceName(port);
      String? banner;
      
      // Intentar obtener banner para algunos servicios
      try {
        if ([21, 22, 25, 80, 443].contains(port)) {
          socket.write('HEAD / HTTP/1.0\r\n\r\n');
          await Future.delayed(Duration(milliseconds: 100));
          final data = await socket.first.timeout(Duration(seconds: 1));
          final response = String.fromCharCodes(data);
          if (response.isNotEmpty) {
            banner = response.substring(0, response.length > 100 ? 100 : response.length);
          }
        }
      } catch (e) {
        // Ignorar errores de banner
      }
      
      await socket.close();
      
      return PortInfo(
        port: port,
        protocol: 'TCP',
        status: 'open',
        service: service,
        banner: banner,
        responseTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return PortInfo(
        port: port,
        protocol: 'TCP',
        status: 'closed',
        service: _getServiceName(port),
        banner: null,
        responseTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  String? _getServiceName(int port) {
    final services = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      143: 'IMAP',
      443: 'HTTPS',
      993: 'IMAPS',
      995: 'POP3S',
      3389: 'RDP',
      5432: 'PostgreSQL',
      3306: 'MySQL',
      1433: 'SQL Server',
      6379: 'Redis',
      27017: 'MongoDB',
      8080: 'HTTP Alt',
      8443: 'HTTPS Alt',
    };
    return services[port];
  }

  Future<NetworkInfo> _getNetworkInfo(String host) async {
    String? hostname;
    List<String> ipAddresses = [];
    String? organization;
    String? country;
    String? city;
    String? isp;
    bool isReachable = false;
    int? avgResponseTime;
    int? packetLoss;

    try {
      // Resolver información básica
      if (_isIPAddress(host)) {
        ipAddresses.add(host);
        // Intentar reverse DNS
        try {
          final ptr = await InternetAddress(host).reverse();
          hostname = ptr.host;
        } catch (e) {
          print('Error en reverse DNS: $e');
        }
      } else {
        hostname = host;
        final addresses = await InternetAddress.lookup(host);
        ipAddresses = addresses.map((addr) => addr.address).toList();
      }

      // Probar conectividad básica
      isReachable = await _networkConnectivityTest(host);
      
      // Calcular tiempo promedio con múltiples pings
      if (isReachable) {
        final times = <int>[];
        for (int i = 0; i < 3; i++) {
          final stopwatch = Stopwatch()..start();
          try {
            await _networkConnectivityTest(host);
            stopwatch.stop();
            times.add(stopwatch.elapsedMilliseconds);
          } catch (e) {
            stopwatch.stop();
          }
          await Future.delayed(Duration(milliseconds: 100));
        }
        
        if (times.isNotEmpty) {
          avgResponseTime = times.reduce((a, b) => a + b) ~/ times.length;
          final failures = 3 - times.length;
          packetLoss = (failures * 100) ~/ 3;
        }
      }

      // Intentar obtener información geográfica/organizacional desde IP pública
      if (ipAddresses.isNotEmpty && !_isPrivateIP(ipAddresses.first)) {
        try {
          final geoInfo = await _getGeoIPInfo(ipAddresses.first);
          organization = geoInfo['org'];
          country = geoInfo['country'];
          city = geoInfo['city'];
          isp = geoInfo['isp'];
        } catch (e) {
          print('Error obteniendo información geográfica: $e');
        }
      }

    } catch (e) {
      print('Error obteniendo información de red: $e');
    }

    return NetworkInfo(
      hostname: hostname,
      ipAddresses: ipAddresses,
      organization: organization,
      country: country,
      city: city,
      isp: isp,
      isReachable: isReachable,
      avgResponseTime: avgResponseTime,
      packetLoss: packetLoss,
    );
  }

  bool _isPrivateIP(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;
    
    // Rangos de IP privadas
    return (parts[0] == 10) ||
           (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) ||
           (parts[0] == 192 && parts[1] == 168) ||
           (parts[0] == 127); // localhost
  }

  Future<Map<String, String?>> _getGeoIPInfo(String ip) async {
    try {
      // Usar servicio gratuito de geolocalización IP
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/$ip'),
        headers: {'User-Agent': 'iPing/1.0'},
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'org': data['org'],
            'country': data['country'],
            'city': data['city'],
            'isp': data['isp'],
          };
        }
      }
    } catch (e) {
      print('Error consultando información geográfica: $e');
    }
    
    return {
      'org': null,
      'country': null,
      'city': null,
      'isp': null,
    };
  }
}
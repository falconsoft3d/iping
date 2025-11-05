class DeepScanResult {
  final String serverId;
  final String serverName;
  final String serverIp;
  final DateTime scanTime;
  final List<DnsRecord> dnsRecords;
  final List<PortInfo> openPorts;
  final List<PortInfo> closedPorts;
  final NetworkInfo networkInfo;
  final List<String> errors;

  DeepScanResult({
    required this.serverId,
    required this.serverName,
    required this.serverIp,
    required this.scanTime,
    required this.dnsRecords,
    required this.openPorts,
    required this.closedPorts,
    required this.networkInfo,
    required this.errors,
  });
}

class DnsRecord {
  final String type; // A, AAAA, MX, NS, CNAME, etc.
  final String name;
  final String value;
  final int? ttl;

  DnsRecord({
    required this.type,
    required this.name,
    required this.value,
    this.ttl,
  });
}

class PortInfo {
  final int port;
  final String protocol; // TCP, UDP
  final String status; // open, closed, filtered
  final String? service; // http, https, ssh, etc.
  final String? banner;
  final int responseTime;

  PortInfo({
    required this.port,
    required this.protocol,
    required this.status,
    this.service,
    this.banner,
    required this.responseTime,
  });
}

class NetworkInfo {
  final String? hostname;
  final List<String> ipAddresses;
  final String? organization;
  final String? country;
  final String? city;
  final String? isp;
  final bool isReachable;
  final int? avgResponseTime;
  final int? packetLoss;

  NetworkInfo({
    this.hostname,
    required this.ipAddresses,
    this.organization,
    this.country,
    this.city,
    this.isp,
    required this.isReachable,
    this.avgResponseTime,
    this.packetLoss,
  });
}
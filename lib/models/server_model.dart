class ServerModel {
  final String id;
  final String name;
  final String ip;
  bool isOnline;
  int? responseTime;
  DateTime? lastChecked;
  bool isMonitoring;
  final List<PingHistoryEntry> history;

  ServerModel({
    required this.id,
    required this.name,
    required this.ip,
    this.isOnline = false,
    this.responseTime,
    this.lastChecked,
    this.isMonitoring = false,
    this.history = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'isOnline': isOnline,
      'responseTime': responseTime,
      'lastChecked': lastChecked?.toIso8601String(),
      'isMonitoring': isMonitoring,
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'],
      name: json['name'],
      ip: json['ip'],
      isOnline: json['isOnline'] ?? false,
      responseTime: json['responseTime'],
      lastChecked: json['lastChecked'] != null
          ? DateTime.parse(json['lastChecked'])
          : null,
      isMonitoring: json['isMonitoring'] ?? false,
      history: (json['history'] as List<dynamic>?)
          ?.map((e) => PingHistoryEntry.fromJson(e))
          .toList() ?? [],
    );
  }

  ServerModel copyWith({
    String? id,
    String? name,
    String? ip,
    bool? isOnline,
    int? responseTime,
    DateTime? lastChecked,
    bool? isMonitoring,
    List<PingHistoryEntry>? history,
  }) {
    return ServerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      isOnline: isOnline ?? this.isOnline,
      responseTime: responseTime ?? this.responseTime,
      lastChecked: lastChecked ?? this.lastChecked,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      history: history ?? this.history,
    );
  }
}

class PingHistoryEntry {
  final DateTime timestamp;
  final bool isOnline;
  final int? responseTime;
  final String? errorMessage;

  PingHistoryEntry({
    required this.timestamp,
    required this.isOnline,
    this.responseTime,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'isOnline': isOnline,
      'responseTime': responseTime,
      'errorMessage': errorMessage,
    };
  }

  factory PingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PingHistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      isOnline: json['isOnline'] ?? false,
      responseTime: json['responseTime'],
      errorMessage: json['errorMessage'],
    );
  }
}
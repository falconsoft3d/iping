import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/server_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'iping.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de servidores
    await db.execute('''
      CREATE TABLE servers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ip TEXT NOT NULL,
        is_online INTEGER DEFAULT 0,
        response_time INTEGER,
        last_checked TEXT,
        is_monitoring INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabla de historial de pings
    await db.execute('''
      CREATE TABLE ping_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_online INTEGER NOT NULL,
        response_time INTEGER,
        error_message TEXT,
        FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE CASCADE
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('''
      CREATE INDEX idx_servers_name ON servers (name)
    ''');

    await db.execute('''
      CREATE INDEX idx_ping_history_server_id ON ping_history (server_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_ping_history_timestamp ON ping_history (timestamp)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar futuras actualizaciones de la base de datos
    if (oldVersion < 2) {
      // Ejemplo para futuras versiones
      // await db.execute('ALTER TABLE servers ADD COLUMN new_column TEXT');
    }
  }

  // CRUD para servidores
  Future<String> insertServer(ServerModel server) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.insert(
      'servers',
      {
        'id': server.id,
        'name': server.name,
        'ip': server.ip,
        'is_online': server.isOnline ? 1 : 0,
        'response_time': server.responseTime,
        'last_checked': server.lastChecked?.toIso8601String(),
        'is_monitoring': server.isMonitoring ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    return server.id;
  }

  Future<List<ServerModel>> getAllServers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servers',
      orderBy: 'name ASC',
    );

    List<ServerModel> servers = [];
    
    for (var map in maps) {
      // Obtener el historial para cada servidor
      final history = await getPingHistory(map['id']);
      
      servers.add(ServerModel(
        id: map['id'],
        name: map['name'],
        ip: map['ip'],
        isOnline: map['is_online'] == 1,
        responseTime: map['response_time'],
        lastChecked: map['last_checked'] != null 
            ? DateTime.parse(map['last_checked']) 
            : null,
        isMonitoring: map['is_monitoring'] == 1,
        history: history,
      ));
    }

    return servers;
  }

  Future<ServerModel?> getServer(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'servers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      final history = await getPingHistory(id);
      
      return ServerModel(
        id: map['id'],
        name: map['name'],
        ip: map['ip'],
        isOnline: map['is_online'] == 1,
        responseTime: map['response_time'],
        lastChecked: map['last_checked'] != null 
            ? DateTime.parse(map['last_checked']) 
            : null,
        isMonitoring: map['is_monitoring'] == 1,
        history: history,
      );
    }

    return null;
  }

  Future<void> updateServer(ServerModel server) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.update(
      'servers',
      {
        'name': server.name,
        'ip': server.ip,
        'is_online': server.isOnline ? 1 : 0,
        'response_time': server.responseTime,
        'last_checked': server.lastChecked?.toIso8601String(),
        'is_monitoring': server.isMonitoring ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  Future<void> deleteServer(String id) async {
    final db = await database;
    
    // Eliminar historial primero (por la clave foránea)
    await db.delete(
      'ping_history',
      where: 'server_id = ?',
      whereArgs: [id],
    );
    
    // Eliminar servidor
    await db.delete(
      'servers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD para historial de pings
  Future<void> insertPingHistory(String serverId, PingHistoryEntry entry) async {
    final db = await database;
    
    await db.insert(
      'ping_history',
      {
        'server_id': serverId,
        'timestamp': entry.timestamp.toIso8601String(),
        'is_online': entry.isOnline ? 1 : 0,
        'response_time': entry.responseTime,
        'error_message': entry.errorMessage,
      },
    );
    
    // Mantener solo los últimos 100 registros por servidor
    await _cleanupOldPingHistory(serverId);
  }

  Future<List<PingHistoryEntry>> getPingHistory(String serverId, {int? limit}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ping_history',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'timestamp DESC',
      limit: limit ?? 100,
    );

    return maps.map((map) => PingHistoryEntry(
      timestamp: DateTime.parse(map['timestamp']),
      isOnline: map['is_online'] == 1,
      responseTime: map['response_time'],
      errorMessage: map['error_message'],
    )).toList();
  }

  Future<void> _cleanupOldPingHistory(String serverId) async {
    final db = await database;
    
    // Obtener el count actual
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ping_history WHERE server_id = ?',
      [serverId],
    );
    
    final count = countResult.first['count'] as int;
    
    if (count > 100) {
      // Eliminar los registros más antiguos, manteniendo solo los últimos 100
      await db.rawDelete('''
        DELETE FROM ping_history 
        WHERE server_id = ? 
        AND id NOT IN (
          SELECT id FROM ping_history 
          WHERE server_id = ? 
          ORDER BY timestamp DESC 
          LIMIT 100
        )
      ''', [serverId, serverId]);
    }
  }

  Future<void> clearAllPingHistory(String serverId) async {
    final db = await database;
    await db.delete(
      'ping_history',
      where: 'server_id = ?',
      whereArgs: [serverId],
    );
  }

  // Métodos de utilidad
  Future<int> getServerCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM servers');
    return result.first['count'] as int;
  }

  Future<int> getPingHistoryCount(String serverId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ping_history WHERE server_id = ?',
      [serverId],
    );
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getServerStatistics() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        s.id,
        s.name,
        s.ip,
        s.is_online,
        s.last_checked,
        COUNT(ph.id) as ping_count,
        AVG(ph.response_time) as avg_response_time,
        (SELECT COUNT(*) FROM ping_history WHERE server_id = s.id AND is_online = 1) as successful_pings,
        (SELECT COUNT(*) FROM ping_history WHERE server_id = s.id AND is_online = 0) as failed_pings
      FROM servers s
      LEFT JOIN ping_history ph ON s.id = ph.server_id
      GROUP BY s.id, s.name, s.ip, s.is_online, s.last_checked
      ORDER BY s.name ASC
    ''');
  }

  // Método para insertar servidores de ejemplo
  Future<void> insertDefaultServers() async {
    final count = await getServerCount();
    if (count == 0) {
      final defaultServers = [
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

      for (final server in defaultServers) {
        await insertServer(server);
      }
    }
  }

  // Método para migrar datos desde SharedPreferences (opcional)
  Future<void> migrateFromSharedPreferences(List<String> serversJson) async {
    if (serversJson.isNotEmpty) {
      final count = await getServerCount();
      if (count == 0) {
        // Solo migrar si no hay servidores en la BD
        for (final serverJsonString in serversJson) {
          try {
            final Map<String, dynamic> serverJson = Map<String, dynamic>.from(
              const JsonDecoder().convert(serverJsonString)
            );
            final server = ServerModel.fromJson(serverJson);
            await insertServer(server);
            
            // Si hay historial en el JSON, también migrarlo
            if (server.history.isNotEmpty) {
              for (final historyEntry in server.history) {
                await insertPingHistory(server.id, historyEntry);
              }
            }
          } catch (e) {
            print('Error migrando servidor: $e');
          }
        }
      }
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
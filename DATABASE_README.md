# Base de Datos SQLite - iPing

## Descripción
Esta implementación reemplaza el almacenamiento con SharedPreferences por una base de datos SQLite más robusta y eficiente para gestionar servidores y su historial de pings.

## Características Implementadas

### 1. Base de Datos SQLite
- **Archivo**: `lib/database/database_helper.dart`
- **Base de datos**: `iping.db`
- **Versión**: 1

### 2. Estructura de Tablas

#### Tabla `servers`
```sql
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
```

#### Tabla `ping_history`
```sql
CREATE TABLE ping_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  server_id TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  is_online INTEGER NOT NULL,
  response_time INTEGER,
  error_message TEXT,
  FOREIGN KEY (server_id) REFERENCES servers (id) ON DELETE CASCADE
)
```

### 3. Funcionalidades

#### CRUD de Servidores
- ✅ **Crear**: `insertServer(ServerModel server)`
- ✅ **Leer**: `getAllServers()`, `getServer(String id)`
- ✅ **Actualizar**: `updateServer(ServerModel server)`
- ✅ **Eliminar**: `deleteServer(String id)`

#### Gestión del Historial
- ✅ **Insertar ping**: `insertPingHistory(String serverId, PingHistoryEntry entry)`
- ✅ **Obtener historial**: `getPingHistory(String serverId, {int? limit})`
- ✅ **Limpiar historial**: `clearAllPingHistory(String serverId)`
- ✅ **Limpieza automática**: Mantiene solo los últimos 100 registros por servidor

#### Estadísticas
- ✅ **Estadísticas generales**: `getServerStatistics()`
- ✅ **Contadores**: `getServerCount()`, `getPingHistoryCount(String serverId)`

### 4. Pantalla de Estadísticas
- **Archivo**: `lib/screens/statistics_screen.dart`
- **Acceso**: Botón en el AppBar de la pantalla principal
- **Información mostrada**:
  - Total de pings por servidor
  - Pings exitosos vs fallidos
  - Tasa de éxito (%)
  - Tiempo de respuesta promedio
  - Última verificación
  - Barra de confiabilidad visual

### 5. Persistencia de Datos
- ✅ **Persistencia automática**: Todos los datos se guardan automáticamente
- ✅ **Recuperación al iniciar**: Los datos persisten entre sesiones
- ✅ **Migración opcional**: Método para migrar desde SharedPreferences

### 6. Optimizaciones Implementadas

#### Índices de Base de Datos
```sql
CREATE INDEX idx_servers_name ON servers (name);
CREATE INDEX idx_ping_history_server_id ON ping_history (server_id);
CREATE INDEX idx_ping_history_timestamp ON ping_history (timestamp);
```

#### Gestión de Memoria
- Limpieza automática del historial (máximo 100 entradas por servidor)
- Carga eficiente de datos con LIMIT
- Uso de transacciones para operaciones múltiples

### 7. Integración con Provider
El `PingProvider` ha sido actualizado para:
- ✅ Usar SQLite en lugar de SharedPreferences
- ✅ Guardar automáticamente cada ping en la base de datos
- ✅ Mantener sincronización entre memoria y base de datos
- ✅ Proporcionar métodos adicionales para estadísticas

## Ventajas sobre SharedPreferences

### Rendimiento
- **Consultas SQL**: Búsquedas y filtros más eficientes
- **Índices**: Búsquedas optimizadas por nombre, servidor y timestamp
- **Carga selectiva**: Solo cargar datos necesarios

### Escalabilidad
- **Historial ilimitado**: No hay límites de tamaño como en SharedPreferences
- **Consultas complejas**: Estadísticas y agregaciones
- **Relaciones**: Foreign keys para integridad de datos

### Funcionalidad
- **Transacciones**: Operaciones atómicas
- **Integridad**: Validación de datos a nivel de base de datos
- **Backup/Restore**: Archivo único de base de datos fácil de respaldar

## Uso

### Acceso a la Base de Datos
```dart
final dbHelper = DatabaseHelper();
```

### Agregar un Servidor
```dart
await dbHelper.insertServer(server);
```

### Obtener Estadísticas
```dart
final stats = await dbHelper.getServerStatistics();
```

### Limpiar Historial
```dart
await dbHelper.clearAllPingHistory(serverId);
```

## Migración

Si tienes datos existentes en SharedPreferences, el sistema los puede migrar automáticamente:

```dart
// En el provider, al cargar datos
final prefs = await SharedPreferences.getInstance();
final oldServers = prefs.getStringList('servers') ?? [];
if (oldServers.isNotEmpty) {
  await _dbHelper.migrateFromSharedPreferences(oldServers);
}
```

## Archivos Modificados/Creados

### Nuevos Archivos
- `lib/database/database_helper.dart` - Helper principal de SQLite
- `lib/screens/statistics_screen.dart` - Pantalla de estadísticas

### Archivos Modificados
- `pubspec.yaml` - Añadidas dependencias sqflite y path
- `lib/providers/ping_provider.dart` - Integración con SQLite
- `lib/screens/main_screen.dart` - Botón de estadísticas

## Próximos Pasos Sugeridos

1. **Exportar/Importar datos**: Funcionalidad para backup
2. **Filtros en estadísticas**: Por fecha, estado, etc.
3. **Gráficos**: Visualización temporal del rendimiento
4. **Notificaciones**: Alertas cuando servidores fallen
5. **Configuración avanzada**: Intervalos personalizados de ping

## Comandos de Desarrollo

```bash
# Instalar dependencias
flutter pub get

# Ejecutar análisis
flutter analyze

# Compilar para macOS
flutter build macos

# Ejecutar aplicación
flutter run -d macos
```
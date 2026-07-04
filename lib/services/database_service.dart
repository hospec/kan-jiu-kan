import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/channel.dart';
import '../models/signal_source.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _database;
  DatabaseService._();
  factory DatabaseService() { _instance ??= DatabaseService._(); return _instance!; }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kanjiukan.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE channels (id TEXT PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL, logo_url TEXT, epg_id TEXT, sort_order INTEGER DEFAULT 0)");
    await db.execute("CREATE TABLE signal_sources (id TEXT PRIMARY KEY, channel_id TEXT NOT NULL, url TEXT NOT NULL, format TEXT DEFAULT 'unknown', resolution TEXT, bitrate INTEGER, latency_ms INTEGER, is_available INTEGER DEFAULT 1, last_checked TEXT, success_rate REAL DEFAULT 1.0, priority INTEGER DEFAULT 0, FOREIGN KEY (channel_id) REFERENCES channels(id) ON DELETE CASCADE)");
    await db.execute("CREATE INDEX idx_sources_channel ON signal_sources(channel_id)");
    await db.execute("CREATE INDEX idx_sources_available ON signal_sources(is_available)");
  }

  Future<void> insertChannels(List<Channel> channels) async {
    final db = await database;
    final batch = db.batch();
    for (final c in channels) { batch.insert('channels', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  Future<List<Channel>> getAllChannels() async {
    final db = await database;
    final maps = await db.query('channels', orderBy: 'sort_order ASC');
    return maps.map((m) => Channel.fromMap(m)).toList();
  }

  Future<Map<String, List<Channel>>> getCategorizedChannels() async {
    final all = await getAllChannels();
    final result = <String, List<Channel>>{};
    for (final c in all) { result.putIfAbsent(c.category, () => []).add(c); }
    return result;
  }

  Future<void> insertSources(List<SignalSource> sources) async {
    final db = await database;
    final batch = db.batch();
    for (final s in sources) { batch.insert('signal_sources', s.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); }
    await batch.commit(noResult: true);
  }

  Future<SignalSource?> getBestSource(String channelId) async {
    final db = await database;
    final maps = await db.query('signal_sources', where: 'channel_id = ? AND is_available = 1', whereArgs: [channelId], orderBy: 'priority DESC, success_rate DESC', limit: 1);
    if (maps.isEmpty) return null;
    return SignalSource.fromMap(maps.first);
  }

  Future<List<SignalSource>> getSourcesForChannel(String channelId) async {
    final db = await database;
    final maps = await db.query('signal_sources', where: 'channel_id = ?', whereArgs: [channelId], orderBy: 'is_available DESC, priority DESC');
    return maps.map((m) => SignalSource.fromMap(m)).toList();
  }

  Future<void> markSourceUnavailable(String sourceId) async {
    final db = await database;
    await db.update('signal_sources', {'is_available': 0, 'last_checked': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [sourceId]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('signal_sources');
    await db.delete('channels');
  }

  Future<int> getChannelCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM channels');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}

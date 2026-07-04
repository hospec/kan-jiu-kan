import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../models/signal_source.dart';
import 'database_service.dart';
import 'm3u_parser.dart';

const _categoryPatterns = <String, List<String>>{
  '央视': ['CCTV', 'CGTN'],
  '香港': ['翡翠', '凤凰', 'TVB', 'ViuTV', 'HOY', '明珠', '无线', '港台'],
  '广东本地': ['广东', '珠江', '民生', '大湾区', '南方', '广州', '深圳'],
  '卫视': ['卫视'],
};

class ChannelManager {
  final DatabaseService _db;
  final M3UParser _parser;
  final _uuid = const Uuid();

  ChannelManager({DatabaseService? db, M3UParser? parser})
      : _db = db ?? DatabaseService(),
        _parser = parser ?? M3UParser();

  Future<ChannelImportResult> importFromUrls(List<String> m3uUrls) async {
    int totalChannels = 0;
    int totalSources = 0;
    for (final url in m3uUrls) {
      try {
        final result = await _parser.fetchAndParse(url);
        final items = _buildChannelsAndSources(result);
        await _db.insertChannels(items.channels);
        await _db.insertSources(items.sources);
        totalChannels += items.channels.length;
        totalSources += items.sources.length;
      } catch (e) {
        // skip failed sources
      }
    }
    return ChannelImportResult(channelCount: totalChannels, sourceCount: totalSources);
  }

  Future<ChannelImportResult> importFromAsset({String assetPath = 'assets/initial_sources.m3u'}) async {
    final content = await rootBundle.loadString(assetPath);
    final result = _parser.parse(content);
    final items = _buildChannelsAndSources(result);
    print('Parsed channels: \${items.channels.length}'); await _db.clearAll();
    await _db.insertChannels(items.channels);
    await _db.insertSources(items.sources);
    print('Inserted channels: \${items.channels.length}, sources: \${items.sources.length}'); print('Categories: \${items.channels.map((c) => c.category).toSet()}'); return ChannelImportResult(channelCount: items.channels.length, sourceCount: items.sources.length);
  }

  _ChannelSourcePair _buildChannelsAndSources(M3UParseResult result) {
    final channels = <Channel>[];
    final sources = <SignalSource>[];
    for (final entry in result.channels.entries) {
      final category = _classifyChannel(entry.key);
      final channelId = _uuid.v4();
      channels.add(Channel(id: channelId, name: entry.key, category: category, sortOrder: _categorySortOrder(category)));
      for (final url in entry.value) {
        sources.add(SignalSource(id: _uuid.v4(), channelId: channelId, url: url, format: SignalSource.detectFormat(url)));
      }
    }
    return _ChannelSourcePair(channels, sources);
  }

  String _classifyChannel(String name) {
    for (final entry in _categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (name.contains(pattern)) return entry.key;
      }
    }
    return '其他';
  }

  int _categorySortOrder(String category) {
    const order = {'央视': 0, '卫视': 1, '广东本地': 2, '香港': 3, '其他': 4};
    return order[category] ?? 99;
  }

  Future<Map<String, List<Channel>>> getCategorizedChannels() => _db.getCategorizedChannels();
  Future<SignalSource?> getBestSource(String channelId) => _db.getBestSource(channelId);
  Future<List<SignalSource>> getAlternativeSources(String channelId) => _db.getSourcesForChannel(channelId);
  Future<SignalSource?> fallbackToNextSource(String channelId, String failedSourceId) async {
    await _db.markSourceUnavailable(failedSourceId);
    return _db.getBestSource(channelId);
  }
  Future<int> getChannelCount() => _db.getChannelCount();
}

class _ChannelSourcePair {
  final List<Channel> channels;
  final List<SignalSource> sources;
  _ChannelSourcePair(this.channels, this.sources);
}

class ChannelImportResult {
  final int channelCount;
  final int sourceCount;
  const ChannelImportResult({required this.channelCount, required this.sourceCount});
}

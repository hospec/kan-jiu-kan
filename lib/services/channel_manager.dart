import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/channel.dart';
import '../models/signal_source.dart';
import 'database_service.dart';
import 'm3u_parser.dart';

/// 频道分类名称映射（用于识别频道归属）
const _categoryPatterns = <String, List<String>>{
  '央视': ['CCTV', 'CGTN'],
  '卫视': ['卫视', 'TV'],
  '广东本地': ['广东', '珠江', '民生', '大湾区', '南方', '广州', '深圳'],
  '香港': ['翡翠', '凤凰', 'TVB', 'ViuTV', 'HOY', '明珠', '无线', '港台'],
};

class ChannelManager {
  final DatabaseService _db;
  final M3UParser _parser;
  final _uuid = const Uuid();

  ChannelManager({DatabaseService? db, M3UParser? parser})
      : _db = db ?? DatabaseService(),
        _parser = parser ?? M3UParser();

  /// 从 URL 列表导入频道和信号源
  Future<ChannelImportResult> importFromUrls(List<String> m3uUrls) async {
    int totalChannels = 0;
    int totalSources = 0;

    for (final url in m3uUrls) {
      try {
        final result = await _parser.fetchAndParse(url);
        final channels = <Channel>[];
        final sources = <SignalSource>[];

        for (final entry in result.channels.entries) {
          final category = _classifyChannel(entry.key);
          final channelId = _uuid.v4();
          channels.add(Channel(
            id: channelId,
            name: entry.key,
            category: category,
            sortOrder: _categorySortOrder(category),
          ));

          for (final url in entry.value) {
            sources.add(SignalSource(
              id: _uuid.v4(),
              channelId: channelId,
              url: url,
              format: SignalSource.detectFormat(url),
            ));
          }
        }

        await _db.insertChannels(channels);
        await _db.insertSources(sources);
        totalChannels += channels.length;
        totalSources += sources.length;
      } catch (e) {
        // 单个源失败不中断整体流程
        print('Failed to import from $url: $e');
      }
    }

    return ChannelImportResult(
      channelCount: totalChannels,
      sourceCount: totalSources,
    );
  }

  /// 根据频道名分类
  String _classifyChannel(String name) {
    for (final entry in _categoryPatterns.entries) {
      for (final pattern in entry.value) {
        if (name.contains(pattern)) return entry.key;
      }
    }
    return '其他';
  }

  int _categorySortOrder(String category) {
    const order = {
      '央视': 0, '卫视': 1, '广东本地': 2, '香港': 3, '其他': 4
    };
    return order[category] ?? 99;
  }

  /// 获取分类频道列表（用于 UI 展示）
  Future<Map<String, List<Channel>>> getCategorizedChannels() =>
      _db.getCategorizedChannels();

  /// 获取某频道的最优信号源
  Future<SignalSource?> getBestSource(String channelId) =>
      _db.getBestSource(channelId);

  /// 获取某频道的所有备选源
  Future<List<SignalSource>> getAlternativeSources(String channelId) =>
      _db.getSourcesForChannel(channelId);

  /// 标记源不可用并返回下一个备选
  Future<SignalSource?> fallbackToNextSource(
      String channelId, String failedSourceId) async {
    await _db.markSourceUnavailable(failedSourceId);
    return _db.getBestSource(channelId);
  }

  /// 获取已缓存的频道总数
  Future<int> getChannelCount() => _db.getChannelCount();
}

class ChannelImportResult {
  final int channelCount;
  final int sourceCount;
  const ChannelImportResult({required this.channelCount, required this.sourceCount});
}

import 'dart:convert';
import 'package:dio/dio.dart';

class M3UParseResult {
  final Map<String, List<String>> channels;
  final int totalEntries;
  const M3UParseResult({required this.channels, required this.totalEntries});
}

class M3UParser {
  final Dio _dio;
  M3UParser({Dio? dio}) : _dio = dio ?? Dio();

  Future<M3UParseResult> fetchAndParse(String url) async {
    final response = await _dio.get<String>(url, options: Options(responseType: ResponseType.plain, receiveTimeout: const Duration(seconds: 15)));
    if (response.data == null) throw Exception('Empty response from $url');
    return parse(response.data!);
  }

  M3UParseResult parse(String content) {
    final channels = <String, List<String>>{};
    final lines = const LineSplitter().convert(content);
    String? currentName;
    int entries = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed == '#EXTM3U') continue;
      if (trimmed.startsWith('#EXTINF:')) {
        currentName = _extractChannelName(trimmed);
      } else if (!trimmed.startsWith('#') && currentName != null) {
        channels.putIfAbsent(currentName, () => []).add(trimmed);
        entries++;
        currentName = null;
      }
    }
    print('M3U Parser: \${channels.length} channels, \${entries} entries total'); return M3UParseResult(channels: channels, totalEntries: entries);
  }

  String _extractChannelName(String extinfLine) {
    final tvgMatch = RegExp(r'tvg-name="([^"]*)"').firstMatch(extinfLine);
    if (tvgMatch != null && tvgMatch.group(1)!.isNotEmpty) return tvgMatch.group(1)!.trim();
    final parts = extinfLine.split(',');
    if (parts.length >= 2) return parts.sublist(1).join(',').trim();
    return 'Unknown';
  }
}

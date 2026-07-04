/// 信号源数据模型
enum SourceFormat { m3u8, rtmp, rtsp, http, unknown }

class SignalSource {
  final String id;
  final String channelId;
  final String url;
  final SourceFormat format;
  final String? resolution;
  final int? bitrate;
  final int? latencyMs;
  final bool isAvailable;
  final DateTime? lastChecked;
  final double successRate;
  final int priority;

  const SignalSource({
    required this.id,
    required this.channelId,
    required this.url,
    this.format = SourceFormat.unknown,
    this.resolution,
    this.bitrate,
    this.latencyMs,
    this.isAvailable = true,
    this.lastChecked,
    this.successRate = 1.0,
    this.priority = 0,
  });

  SignalSource copyWith({
    String? id,
    String? channelId,
    String? url,
    SourceFormat? format,
    String? resolution,
    int? bitrate,
    int? latencyMs,
    bool? isAvailable,
    DateTime? lastChecked,
    double? successRate,
    int? priority,
  }) {
    return SignalSource(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      url: url ?? this.url,
      format: format ?? this.format,
      resolution: resolution ?? this.resolution,
      bitrate: bitrate ?? this.bitrate,
      latencyMs: latencyMs ?? this.latencyMs,
      isAvailable: isAvailable ?? this.isAvailable,
      lastChecked: lastChecked ?? this.lastChecked,
      successRate: successRate ?? this.successRate,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'channel_id': channelId,
    'url': url,
    'format': format.name,
    'resolution': resolution,
    'bitrate': bitrate,
    'latency_ms': latencyMs,
    'is_available': isAvailable ? 1 : 0,
    'last_checked': lastChecked?.toIso8601String(),
    'success_rate': successRate,
    'priority': priority,
  };

  factory SignalSource.fromMap(Map<String, dynamic> map) {
    final fmt = map['format'] as String? ?? 'unknown';
    return SignalSource(
      id: map['id'] as String,
      channelId: map['channel_id'] as String,
      url: map['url'] as String,
      format: SourceFormat.values.firstWhere(
        (e) => e.name == fmt,
        orElse: () => SourceFormat.unknown,
      ),
      resolution: map['resolution'] as String?,
      bitrate: map['bitrate'] as int?,
      latencyMs: map['latency_ms'] as int?,
      isAvailable: (map['is_available'] as int?) == 1,
      lastChecked: map['last_checked'] != null
          ? DateTime.tryParse(map['last_checked'] as String)
          : null,
      successRate: (map['success_rate'] as num?)?.toDouble() ?? 1.0,
      priority: map['priority'] as int? ?? 0,
    );
  }

  /// 检测源格式（从URL后缀推断）
  static SourceFormat detectFormat(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('m3u8')) return SourceFormat.m3u8;
    if (lower.startsWith('rtmp')) return SourceFormat.rtmp;
    if (lower.startsWith('rtsp')) return SourceFormat.rtsp;
    if (lower.startsWith('http')) return SourceFormat.http;
    return SourceFormat.unknown;
  }
}

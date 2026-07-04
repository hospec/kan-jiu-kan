/// 电视频道数据模型
class Channel {
  final String id;
  final String name;
  final String category;     // "央视" | "卫视" | "广东本地" | "香港" | "其他"
  final String? logoUrl;
  final String? epgId;
  final int sortOrder;

  const Channel({
    required this.id,
    required this.name,
    required this.category,
    this.logoUrl,
    this.epgId,
    this.sortOrder = 0,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? category,
    String? logoUrl,
    String? epgId,
    int? sortOrder,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      logoUrl: logoUrl ?? this.logoUrl,
      epgId: epgId ?? this.epgId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category,
    'logo_url': logoUrl,
    'epg_id': epgId,
    'sort_order': sortOrder,
  };

  factory Channel.fromMap(Map<String, dynamic> map) => Channel(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String,
    logoUrl: map['logo_url'] as String?,
    epgId: map['epg_id'] as String?,
    sortOrder: map['sort_order'] as int? ?? 0,
  );

  @override
  String toString() => 'Channel($name, $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Channel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

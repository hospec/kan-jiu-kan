import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/channel_manager.dart';
import '../widgets/channel_card.dart';
import '../widgets/category_tabs.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final _channelManager = ChannelManager();
  Map<String, List<Channel>> _categorizedChannels = {};
  String _selectedCategory = '';
  bool _loading = true;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _loading = true);
    try {
      _categorizedChannels = await _channelManager.getCategorizedChannels();
      _categories = _categorizedChannels.keys.toList();
      _categories.sort((a, b) {
        const order = {'央视': 0, '卫视': 1, '广东本地': 2, '香港': 3};
        return (order[a] ?? 99).compareTo(order[b] ?? 99);
      });
      if (_selectedCategory.isEmpty && _categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
    } catch (e) {
      _showError('加载频道失败: $e');
    }
    setState(() => _loading = false);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final channels = _categorizedChannels[_selectedCategory] ?? [];

    return Column(
      children: [
        // 顶部标题栏
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Text('想看就看',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
              const Spacer(),
              _buildActionButton(Icons.refresh, '刷新信号源', _onRefreshSources),
              const SizedBox(width: 16),
              _buildActionButton(Icons.sync, '快速更新', _onQuickUpdate),
            ],
          ),
        ),
        // 分类标签
        if (_categories.isNotEmpty)
          CategoryTabs(
            categories: _categories,
            selected: _selectedCategory,
            onChanged: (cat) => setState(() => _selectedCategory = cat),
          ),
        const SizedBox(height: 16),
        // 频道网格
        Expanded(
          child: channels.isEmpty
              ? const Center(child: Text('暂无频道数据,请点击刷新按钮更新信号源', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    return ChannelCard(channel: channels[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Focus(
        descendantsAreFocusable: false,
        child: Builder(builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: hasFocus ? const Color(0xFFE53935) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: hasFocus ? Colors.transparent : Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          );
        }),
      ),
    );
  }

  void _onRefreshSources() {
    // TODO: 打开信号源更新页面 (QR code HTTP 服务)
    _showError('信号源更新功能即将上线');
  }

  void _onQuickUpdate() {
    // TODO: 快速更新 - 从内置源刷新
    _loadChannels();
  }
}

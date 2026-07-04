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
    _initChannels();
  }

  Future<void> _initChannels() async {
    setState(() => _loading = true);
    try {
      final count = await _channelManager.getChannelCount();
      if (count == 0) {
        await _channelManager.importFromAsset();
      }
      final categorized = await _channelManager.getCategorizedChannels();
      final cats = categorized.keys.toList();
      cats.sort((a, b) {
        const order = {'央视': 0, '卫视': 1, '广东本地': 2, '香港': 3};
        return (order[a] ?? 99).compareTo(order[b] ?? 99);
      });
      if (mounted) {
        setState(() {
          _categorizedChannels = categorized;
          _categories = cats;
          if (_selectedCategory.isEmpty && cats.isNotEmpty) {
            _selectedCategory = cats.first;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: \$e'), backgroundColor: Colors.red[800]),
        );
      }
    }
  }

  Future<void> _refreshChannels() async {
    setState(() => _loading = true);
    try {
      await _channelManager.importFromAsset();
      await _initChannels();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Text('想看就看',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
              const Spacer(),
              _buildActionButton(Icons.refresh, '刷新频道', _refreshChannels),
            ],
          ),
        ),
        if (_categories.isNotEmpty)
          CategoryTabs(
            categories: _categories,
            selected: _selectedCategory,
            onChanged: (cat) => setState(() => _selectedCategory = cat),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: channels.isEmpty
              ? const Center(child: Text('暂无频道数据', style: TextStyle(fontSize: 18, color: Colors.grey)))
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
}

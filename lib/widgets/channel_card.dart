import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/channel_manager.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  final FocusNode focusNode;
  const ChannelCard({super.key, required this.channel, required this.focusNode});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  String? _sourceUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSource();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSource() async {
    try {
      final source = await ChannelManager().getBestSource(widget.channel.id);
      if (mounted) setState(() { _sourceUrl = source?.url; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = widget.focusNode.hasFocus;

    return GestureDetector(
      onTap: _sourceUrl != null ? () => _openPlayer(_sourceUrl!) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: hasFocus ? const Color(0xFFE53935).withAlpha(30) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasFocus ? const Color(0xFFE53935) : Colors.white12,
            width: hasFocus ? 3 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.channel.name,
              style: TextStyle(
                fontSize: hasFocus ? 20 : 18,
                fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _sourceUrl != null ? Icons.play_circle_outline : Icons.signal_wifi_off,
                    color: _sourceUrl != null ? Colors.green : Colors.red[400],
                    size: 20,
                  ),
          ],
        ),
      ),
    );
  }

  void _openPlayer(String url) {
    Navigator.pushNamed(
      context,
      '/player',
      arguments: {'url': url, 'name': widget.channel.name},
    );
  }
}

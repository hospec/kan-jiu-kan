import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/channel.dart';
import '../services/channel_manager.dart';

class ChannelCard extends StatefulWidget {
  final Channel channel;
  const ChannelCard({super.key, required this.channel});

  @override
  State<ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<ChannelCard> {
  late final FocusNode _focusNode;
  String? _sourceUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocus);
    _loadSource();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSource() async {
    try {
      final source = await ChannelManager().getBestSource(widget.channel.id);
      if (mounted) {
        setState(() {
          _sourceUrl = source?.url;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final canPlay = _sourceUrl != null && !_loading;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select && canPlay) {
          _openPlayer(_sourceUrl!);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: canPlay ? () => _openPlayer(_sourceUrl!) : null,
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

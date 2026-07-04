import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerScreen extends StatefulWidget {
  final String? sourceUrl;
  final String? channelName;

  const PlayerScreen({super.key, this.sourceUrl, this.channelName});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    final url = widget.sourceUrl ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, String>?)?['url'] ??
        '';
    final name = widget.channelName ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, String>?)?['name'] ??
        '';

    if (url.isNotEmpty) {
      _player.open(Media(url));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final url = widget.sourceUrl ?? args?['url'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() => _showInfo = true);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() => _showInfo = false);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video
            Video(controller: _controller),

            // Bottom info bar
            if (_showInfo)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  color: Colors.black87,
                  child: Row(
                    children: [
                      Text(name2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      Text(url, style: const TextStyle(fontSize: 14, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

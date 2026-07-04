import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _showInfo = false;
  bool _loading = true;
  bool _error = false;
  String _errorMsg = '';
  String _channelName = '';
  String _sourceUrl = '';

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        title: '想看就看',
      ),
    );
    _controller = VideoController(_player);

    _player.stream.error.listen((e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString();
          _loading = false;
        });
      }
    });

    _player.stream.playing.listen((playing) {
      if (playing && mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final name = args['name'] as String? ?? '';
      final url = args['url'] as String? ?? '';
      if (name != _channelName || url != _sourceUrl) {
        _channelName = name;
        _sourceUrl = url;
        if (_sourceUrl.isNotEmpty) {
          _player.open(Media(
            _sourceUrl,
            httpHeaders: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Referer': 'https://live.fanmingming.com/',
            },
          ));
        }
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
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
              if (event.logicalKey == LogicalKeyboardKey.goBack ||
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.pop(context);
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

              // Loading indicator
              if (_loading && !_error)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 60, height: 60,
                          child: CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 4),
                        ),
                        const SizedBox(height: 24),
                        Text(_channelName,
                            style: const TextStyle(fontSize: 24, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('正在加载直播流...',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

              // Error display
              if (_error)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 24),
                          const Text('播放失败',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(_channelName,
                              style: const TextStyle(fontSize: 20, color: Colors.grey)),
                          const SizedBox(height: 16),
                          Text(_errorMsg,
                              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                              textAlign: TextAlign.center,
                              maxLines: 3),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom info bar
              if (_showInfo && !_error)
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    color: Colors.black87,
                    child: Row(
                      children: [
                        Text(_channelName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Spacer(),
                        Text(_sourceUrl,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _retry() {
    setState(() {
      _error = false;
      _loading = true;
    });
    if (_sourceUrl.isNotEmpty) {
      _player.open(Media(
        _sourceUrl,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://live.fanmingming.com/',
        },
      ));
    }
  }
}

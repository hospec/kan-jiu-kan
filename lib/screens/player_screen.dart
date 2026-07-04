import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  bool _showInfo = false;
  bool _loading = true;
  bool _error = false;
  String _errorMsg = '';
  String _channelName = '';
  String _sourceUrl = '';

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
        _initPlayer();
      }
    }
  }

  Future<void> _initPlayer() async {
    _controller?.dispose();
    if (_sourceUrl.isEmpty) return;

    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final uri = Uri.parse(_sourceUrl);
      final controller = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://live.fanmingming.com/',
        },
      );

      await controller.initialize();
      await controller.play();

      controller.addListener(() {
        if (mounted) {
          final isPlaying = controller.value.isPlaying;
          final hasError = controller.value.hasError;
          if (hasError) {
            setState(() {
              _error = true;
              _errorMsg = controller.value.errorDescription ?? '未知错误';
              _loading = false;
            });
          } else if (isPlaying) {
            setState(() => _loading = false);
          }
        }
      });

      if (mounted) {
        _controller = controller;
        if (controller.value.isInitialized && !controller.value.hasError) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
              if (event.logicalKey == LogicalKeyboardKey.goBack) {
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
              if (_controller != null && _controller!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),

              // Loading
              if (_loading && !_error)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 60, height: 60,
                            child: CircularProgressIndicator(color: Color(0xFFE53935), strokeWidth: 4)),
                        const SizedBox(height: 24),
                        Text(_channelName, style: const TextStyle(fontSize: 24, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Text('正在加载直播流...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

              // Error
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
                          Text(_channelName, style: const TextStyle(fontSize: 20, color: Colors.grey)),
                          const SizedBox(height: 16),
                          Text(_errorMsg,
                              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
                              textAlign: TextAlign.center, maxLines: 3),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _initPlayer,
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

              // Info bar
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
}

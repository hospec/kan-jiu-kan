import 'package:flutter/material.dart';
import 'screens/channel_list_screen.dart';
import 'screens/player_screen.dart';

void main() => runApp(const KanJiuKanApp());

class KanJiuKanApp extends StatelessWidget {
  const KanJiuKanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '想看就看',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE53935),
          surface: const Color(0xFF1A1A1A),
          onSurface: const Color(0xFFE0E0E0),
        ),
        fontFamily: 'sans-serif',
      ),
      home: const ChannelListScreen(),
      routes: {
        '/player': (context) => const PlayerScreen(),
      },
    );
  }
}

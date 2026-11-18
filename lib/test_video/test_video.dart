import 'package:flutter/material.dart';
import 'package:nn_youtube_player/nn_youtube_player.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nn_youtube_player demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const LessonScreen(),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  // Replace with any YouTube lesson URL.
  static const String _url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

  bool _learningMode = true;
  bool _lockForward = true;
  bool _lockBackward = false;

  double _percent = 0;
  bool _completed = false;
  final List<String> _events = <String>[];

  // Rebuild the player when config toggles change.
  Key _playerKey = const ValueKey<int>(0);

  void _rebuildPlayer() {
    setState(() {
      _completed = false;
      _percent = 0;
      _playerKey = ValueKey<int>(_events.length + DateTime.now().second);
    });
  }

  void _log(String event) {
    setState(() {
      _events.insert(0, event);
      if (_events.length > 6) _events.removeLast();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nn_youtube_player'),
        actions: <Widget>[
          if (_completed)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.verified, color: Colors.lightGreen),
            ),
        ],
      ),
      body: ListView(
        children: [
          NNYoutubePlayer(
            key: _playerKey,
            controller: _controller,
            videoUrl: _url,
            learningMode: _learningMode,
            lockForwardSeek: _lockForward,
            lockBackwardSeek: _lockBackward,
            saveProgress: true,
            autoResume: true,
            completionThreshold: 95,
            speeds: const <double>[1.0, 1.2, 1.5, 2.0, 3.0, 4.0],
            onPlay: () => _log('▶️ play'),
            onPause: () => _log('⏸️ pause'),
            onProgress: (p) => setState(() => _percent = p.percentage),
            onCompleted: () {
              setState(() => _completed = true);
              _log('🎉 completed');
            },
            onSpeedChanged: (s) => _log('⏩ speed → ${s}x'),
            onFullscreenChanged: (f) => _log(f ? '⛶ fullscreen' : '⛶ exit'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LinearProgressIndicator(value: _percent / 100),
                const SizedBox(height: 8),
                Text('Watched: ${_percent.toStringAsFixed(0)}%'),
                const Divider(height: 32),
                Text('Imperative controls',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: _controller.play,
                      child: const Text('Play'),
                    ),
                    FilledButton.tonal(
                      onPressed: _controller.pause,
                      child: const Text('Pause'),
                    ),
                    FilledButton.tonal(
                      onPressed: _controller.restart,
                      child: const Text('Restart'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          _controller.setPlaybackSpeed(2.0),
                      child: const Text('2.0x'),
                    ),
                    FilledButton.tonal(
                      onPressed: _controller.enterFullscreen,
                      child: const Text('Fullscreen'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text('Configuration',
                    style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  title: const Text('Learning mode'),
                  subtitle: const Text('Anti-skip: no jumping ahead'),
                  value: _learningMode,
                  onChanged: (v) {
                    _learningMode = v;
                    _rebuildPlayer();
                  },
                ),
                SwitchListTile(
                  title: const Text('Lock forward seek'),
                  value: _lockForward,
                  onChanged: (v) {
                    _lockForward = v;
                    _rebuildPlayer();
                  },
                ),
                SwitchListTile(
                  title: const Text('Lock backward seek'),
                  value: _lockBackward,
                  onChanged: (v) {
                    _lockBackward = v;
                    _rebuildPlayer();
                  },
                ),
                const Divider(height: 32),
                Text('Analytics events',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_events.isEmpty)
                  const Text('—')
                else
                  for (final event in _events)
                    Text(event,
                        style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
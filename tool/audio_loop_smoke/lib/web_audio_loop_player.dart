import 'dart:js_interop';

import 'package:web/web.dart' as web;

class WebAudioLoopPlayer {
  final Map<String, web.AudioBuffer> _buffers = {};

  web.AudioContext? _context;
  web.GainNode? _gainNode;
  web.AudioBufferSourceNode? _sourceNode;
  double? _startedAt;
  double? _durationSeconds;

  bool get isPlaying => _sourceNode != null;

  String get contextState => _context?.state ?? 'notCreated';

  Duration? get duration {
    final seconds = _durationSeconds;
    return seconds == null ? null : _toDuration(seconds);
  }

  Duration get position {
    final duration = _durationSeconds;
    if (!isPlaying || duration == null || duration == 0) {
      return Duration.zero;
    }
    return _toDuration(_elapsedSeconds % duration);
  }

  int get completedLoops {
    final duration = _durationSeconds;
    if (!isPlaying || duration == null || duration == 0) {
      return 0;
    }
    return (_elapsedSeconds / duration).floor();
  }

  double get _elapsedSeconds {
    final context = _context;
    final startedAt = _startedAt;
    if (context == null || startedAt == null) {
      return 0;
    }
    return context.currentTime - startedAt;
  }

  Future<void> play(String assetPath) async {
    final context = _context ??= web.AudioContext();

    // Invoke resume() before the first await so this stays inside the user's
    // button gesture. Chrome may otherwise reject audio startup.
    final resumeFuture = context.resume().toDart;
    stop();
    await resumeFuture;

    final buffer = await _loadBuffer(context, assetPath);
    if (context.state != 'running') {
      await context.resume().toDart;
    }

    final gainNode = _gainNode ??= web.GainNode(
      context,
      web.GainOptions(gain: 1.0),
    )..connect(context.destination);
    gainNode.gain.value = 1.0;

    final sourceNode = web.AudioBufferSourceNode(context)
      ..buffer = buffer
      ..loop = true
      ..loopStart = 0
      ..loopEnd = buffer.duration;
    sourceNode.connect(gainNode);
    sourceNode.start();

    _sourceNode = sourceNode;
    _startedAt = context.currentTime;
    _durationSeconds = buffer.duration;
  }

  void stop() {
    final sourceNode = _sourceNode;
    _sourceNode = null;
    _startedAt = null;
    if (sourceNode == null) {
      return;
    }

    try {
      sourceNode.stop();
    } catch (_) {
      // A source can only be started once and may already have stopped.
    }
    sourceNode.disconnect();
  }

  Future<void> dispose() async {
    stop();
    _gainNode?.disconnect();
    final context = _context;
    if (context != null && context.state != 'closed') {
      await context.close().toDart;
    }
  }

  Future<web.AudioBuffer> _loadBuffer(
    web.AudioContext context,
    String assetPath,
  ) async {
    final cached = _buffers[assetPath];
    if (cached != null) {
      return cached;
    }

    final response = await web.window.fetch('assets/$assetPath'.toJS).toDart;
    if (!response.ok) {
      throw StateError(
        'Asset request failed: ${response.status} ${response.statusText}',
      );
    }
    final encodedAudio = await response.arrayBuffer().toDart;
    final decodedAudio = await context.decodeAudioData(encodedAudio).toDart;
    _buffers[assetPath] = decodedAudio;
    return decodedAudio;
  }
}

Duration _toDuration(double seconds) {
  return Duration(
    microseconds: (seconds * Duration.microsecondsPerSecond).round(),
  );
}

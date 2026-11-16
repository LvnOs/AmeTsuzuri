import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'ambient_audio_platform.dart';

const _assetPath = 'assets/audio/rain_room_loop.mp3';

AmbientAudioPlatform createAmbientAudioPlatform() {
  return _WebAmbientAudioPlatform();
}

class _WebAmbientAudioPlatform implements AmbientAudioPlatform {
  web.AudioContext? _context;
  web.GainNode? _gainNode;
  web.AudioBufferSourceNode? _sourceNode;
  web.AudioBuffer? _buffer;
  Future<web.AudioBuffer>? _bufferFuture;
  bool _isDisposed = false;

  @override
  Future<void> activate() {
    _ensureNotDisposed();
    final context = _context ??= web.AudioContext();

    // resume() is invoked synchronously from the user's action before the
    // Service reaches its first await.
    return context.resume().toDart.then<void>((_) {});
  }

  @override
  Future<void> prepare() async {
    _ensureNotDisposed();
    if (_buffer != null) {
      return;
    }

    final pendingBuffer = _bufferFuture ??= _loadAndDecode();
    try {
      final buffer = await pendingBuffer;
      _ensureNotDisposed();
      _buffer = buffer;
    } finally {
      if (identical(_bufferFuture, pendingBuffer)) {
        _bufferFuture = null;
      }
    }
  }

  @override
  void startLoop() {
    _ensureNotDisposed();
    final context = _context;
    final buffer = _buffer;
    if (context == null || buffer == null) {
      throw StateError('Ambient audio is not prepared.');
    }

    stop();

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
    try {
      sourceNode.connect(gainNode);
      sourceNode.start();
      _sourceNode = sourceNode;
    } catch (_) {
      sourceNode.disconnect();
      rethrow;
    }
  }

  @override
  void stop() {
    final sourceNode = _sourceNode;
    _sourceNode = null;
    if (sourceNode == null) {
      return;
    }

    try {
      sourceNode.stop();
    } catch (_) {
      // AudioBufferSourceNode cannot be reused and may already be stopped.
    }
    try {
      sourceNode.disconnect();
    } catch (_) {
      // The node may already be disconnected while an operation is cancelled.
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    stop();

    try {
      _gainNode?.disconnect();
    } catch (_) {
      // The gain node may already be disconnected.
    }
    _gainNode = null;
    _buffer = null;
    _bufferFuture = null;

    final context = _context;
    _context = null;
    if (context != null && context.state != 'closed') {
      await context.close().toDart;
    }
  }

  Future<web.AudioBuffer> _loadAndDecode() async {
    final context = _context;
    if (context == null) {
      throw StateError('AudioContext has not been created.');
    }

    final response = await web.window.fetch('assets/$_assetPath'.toJS).toDart;
    if (!response.ok) {
      throw StateError(
        'Ambient audio asset request failed: '
        '${response.status} ${response.statusText}',
      );
    }
    final encodedAudio = await response.arrayBuffer().toDart;
    return context.decodeAudioData(encodedAudio).toDart;
  }

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('Ambient audio platform has been disposed.');
    }
  }
}

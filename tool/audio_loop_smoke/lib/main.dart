import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'web_audio_loop_player.dart';

void main() {
  runApp(const AudioLoopSmokeApp());
}

class AudioLoopSmokeApp extends StatelessWidget {
  const AudioLoopSmokeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AudioLoopSmokePage(),
    );
  }
}

enum PlaybackEngine {
  justAudio('just_audio'),
  webAudio('Web Audio API');

  const PlaybackEngine(this.label);

  final String label;
}

enum AudioFormat {
  mp3('MP3', 'assets/rain_room_loop.mp3'),
  wav('WAV', 'assets/rain_room_loop.wav');

  const AudioFormat(this.label, this.assetPath);

  final String label;
  final String assetPath;
}

class AudioLoopSmokePage extends StatefulWidget {
  const AudioLoopSmokePage({super.key});

  @override
  State<AudioLoopSmokePage> createState() => _AudioLoopSmokePageState();
}

class _AudioLoopSmokePageState extends State<AudioLoopSmokePage> {
  final AudioPlayer _justAudioPlayer = AudioPlayer();
  final WebAudioLoopPlayer _webAudioPlayer = WebAudioLoopPlayer();

  late final Future<void> _prepareFuture;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<PlayerException> _errorSubscription;

  PlaybackEngine _selectedEngine = PlaybackEngine.justAudio;
  AudioFormat _selectedFormat = AudioFormat.mp3;
  Duration _lastObservedPosition = Duration.zero;
  int _justAudioCompletedLoops = 0;
  bool _isBusy = false;
  String? _errorMessage;
  Timer? _webAudioProgressTimer;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _justAudioPlayer.positionStream.listen((position) {
      final duration = _justAudioPlayer.duration;
      final didWrap =
          _justAudioPlayer.playing &&
          duration != null &&
          _lastObservedPosition > duration * 0.6 &&
          position < const Duration(milliseconds: 500);
      _lastObservedPosition = position;
      if (didWrap && mounted) {
        setState(() => _justAudioCompletedLoops++);
      }
    });
    _errorSubscription = _justAudioPlayer.errorStream.listen((error) {
      if (mounted) {
        setState(() => _errorMessage = 'just_audio error: ${error.message}');
      }
    });
    _prepareFuture = _prepareJustAudio();
  }

  Future<void> _prepareJustAudio() async {
    await _justAudioPlayer.setVolume(1.0);
    await _justAudioPlayer.setLoopMode(LoopMode.one);
    await _justAudioPlayer.setAsset(_selectedFormat.assetPath);
  }

  Future<void> _play() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
      if (_selectedEngine == PlaybackEngine.justAudio) {
        _justAudioCompletedLoops = 0;
      }
    });

    try {
      if (_selectedEngine == PlaybackEngine.webAudio) {
        // play() invokes AudioContext.resume() before its first await.
        await _webAudioPlayer.play(_selectedFormat.assetPath);
        _startWebAudioProgressUpdates();
      } else {
        unawaited(
          _justAudioPlayer.play().catchError((Object error) {
            if (mounted) {
              setState(() => _errorMessage = 'just_audioの再生に失敗しました: $error');
            }
          }),
        );
      }
    } catch (error) {
      _webAudioPlayer.stop();
      if (mounted) {
        setState(() => _errorMessage = 'Web Audio APIの再生に失敗しました: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _stopPlayback() async {
    _webAudioProgressTimer?.cancel();
    _webAudioProgressTimer = null;
    _webAudioPlayer.stop();
    await _justAudioPlayer.pause();
    await _justAudioPlayer.seek(Duration.zero);
    _lastObservedPosition = Duration.zero;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectEngine(PlaybackEngine engine) async {
    if (_isBusy || engine == _selectedEngine) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    await _stopPlayback();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedEngine = engine;
      _isBusy = false;
    });
  }

  Future<void> _selectFormat(AudioFormat format) async {
    if (_isBusy || format == _selectedFormat) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _stopPlayback();
      await _justAudioPlayer.setAsset(format.assetPath);
      await _justAudioPlayer.setVolume(1.0);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedFormat = format;
        _justAudioCompletedLoops = 0;
        _lastObservedPosition = Duration.zero;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = '${format.label}の読み込みに失敗しました: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _startWebAudioProgressUpdates() {
    _webAudioProgressTimer?.cancel();
    _webAudioProgressTimer = Timer.periodic(const Duration(milliseconds: 100), (
      _,
    ) {
      if (!mounted || !_webAudioPlayer.isPlaying) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _webAudioProgressTimer?.cancel();
    unawaited(_positionSubscription.cancel());
    unawaited(_errorSubscription.cancel());
    unawaited(_justAudioPlayer.dispose());
    unawaited(_webAudioPlayer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('雨音 ループ方式比較')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<void>(
            future: _prepareFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('音源の読み込みに失敗しました: ${snapshot.error}');
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }

              return StreamBuilder<PlayerState>(
                stream: _justAudioPlayer.playerStateStream,
                builder: (context, playerSnapshot) {
                  final justAudioState = playerSnapshot.data;
                  final justAudioPlaying = justAudioState?.playing == true;
                  final processingState =
                      justAudioState?.processingState ?? ProcessingState.idle;
                  final isWebAudio = _selectedEngine == PlaybackEngine.webAudio;
                  final isPlaying = isWebAudio
                      ? _webAudioPlayer.isPlaying
                      : justAudioPlaying;
                  final completedLoops = isWebAudio
                      ? _webAudioPlayer.completedLoops
                      : _justAudioCompletedLoops;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<PlaybackEngine>(
                        segments: [
                          for (final engine in PlaybackEngine.values)
                            ButtonSegment(
                              value: engine,
                              label: Text(engine.label),
                            ),
                        ],
                        selected: {_selectedEngine},
                        onSelectionChanged: _isBusy
                            ? null
                            : (selection) => _selectEngine(selection.single),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<AudioFormat>(
                        segments: [
                          for (final format in AudioFormat.values)
                            ButtonSegment(
                              value: format,
                              label: Text(format.label),
                            ),
                        ],
                        selected: {_selectedFormat},
                        onSelectionChanged: _isBusy
                            ? null
                            : (selection) => _selectFormat(selection.single),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isBusy
                            ? '準備中'
                            : isPlaying
                            ? '${_selectedEngine.label} / ${_selectedFormat.label} 再生中'
                            : '${_selectedEngine.label} / ${_selectedFormat.label} 停止中',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '完了ループ: $completedLoops回・現在 ${completedLoops + 1}周目',
                      ),
                      const SizedBox(height: 8),
                      if (isWebAudio)
                        Text(
                          '再生位置: ${_formatDuration(_webAudioPlayer.position)}'
                          ' / ${_formatDuration(_webAudioPlayer.duration)}',
                        )
                      else
                        StreamBuilder<Duration>(
                          stream: _justAudioPlayer.positionStream,
                          initialData: _justAudioPlayer.position,
                          builder: (context, positionSnapshot) {
                            return Text(
                              '再生位置: ${_formatDuration(positionSnapshot.data ?? Duration.zero)}'
                              ' / ${_formatDuration(_justAudioPlayer.duration)}',
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      Text('playing: $isPlaying'),
                      if (isWebAudio)
                        Text(
                          'AudioContext.state: ${_webAudioPlayer.contextState}',
                        )
                      else
                        Text('processingState: ${processingState.name}'),
                      const Text('volume: 1.0'),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: _isBusy || isPlaying ? null : _play,
                            child: const Text('再生'),
                          ),
                          OutlinedButton(
                            onPressed: _isBusy || !isPlaying
                                ? null
                                : _stopPlayback,
                            child: const Text('停止'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: const Text(
                          '状態表示は聴感上の短い途切れを検出しません。'
                          '4パターンそれぞれで同じループ境界を3回以上聴き、'
                          '切替時に二重再生していないことも確認してください。',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) {
    return '--:--.---';
  }
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(
    3,
    '0',
  );
  return '$minutes:$seconds.$milliseconds';
}

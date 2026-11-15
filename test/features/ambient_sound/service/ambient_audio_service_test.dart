import 'dart:async';

import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_platform.dart';
import 'package:ame_tsuzuri/features/ambient_sound/service/ambient_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not start playback before play is requested', () async {
    final audioPlatform = _FakeAmbientAudioPlatform();
    final service = AmbientAudioService.withPlatform(audioPlatform);

    expect(service.state.status, AmbientAudioStatus.stopped);
    expect(audioPlatform.startCount, 0);

    await service.dispose();
  });

  test('play notifies loading and playing after preparation', () async {
    final audioPlatform = _FakeAmbientAudioPlatform();
    final service = AmbientAudioService.withPlatform(audioPlatform);
    final statuses = <AmbientAudioStatus>[];
    service.stateListenable.addListener(() {
      statuses.add(service.state.status);
    });

    await service.play();

    expect(statuses, [AmbientAudioStatus.loading, AmbientAudioStatus.playing]);
    expect(audioPlatform.activateCount, 1);
    expect(audioPlatform.prepareCount, 1);
    expect(audioPlatform.startCount, 1);

    await service.dispose();
  });

  test('stop during preparation prevents a late playback start', () async {
    final prepareCompleter = Completer<void>();
    final audioPlatform = _FakeAmbientAudioPlatform(
      prepareCompleter: prepareCompleter,
    );
    final service = AmbientAudioService.withPlatform(audioPlatform);

    final playFuture = service.play();
    await Future<void>.delayed(Duration.zero);
    expect(service.state.status, AmbientAudioStatus.loading);

    service.stop();
    prepareCompleter.complete();
    await playFuture;

    expect(service.state.status, AmbientAudioStatus.stopped);
    expect(audioPlatform.startCount, 0);

    await service.dispose();
  });

  test('only the latest of multiple play requests starts playback', () async {
    final prepareCompleter = Completer<void>();
    final audioPlatform = _FakeAmbientAudioPlatform(
      prepareCompleter: prepareCompleter,
    );
    final service = AmbientAudioService.withPlatform(audioPlatform);

    final firstPlay = service.play();
    await Future<void>.delayed(Duration.zero);
    final secondPlay = service.play();
    await Future<void>.delayed(Duration.zero);
    prepareCompleter.complete();
    await Future.wait([firstPlay, secondPlay]);

    expect(service.state.status, AmbientAudioStatus.playing);
    expect(audioPlatform.startCount, 1);

    await service.dispose();
  });

  test('pause discards the source and resume starts a new one', () async {
    final audioPlatform = _FakeAmbientAudioPlatform();
    final service = AmbientAudioService.withPlatform(audioPlatform);

    await service.play();
    service.pause();

    expect(service.state.status, AmbientAudioStatus.paused);
    expect(audioPlatform.stopCount, 2);

    await service.resume();

    expect(service.state.status, AmbientAudioStatus.playing);
    expect(audioPlatform.startCount, 2);

    await service.dispose();
  });

  test('dispose during preparation prevents a late playback start', () async {
    final prepareCompleter = Completer<void>();
    final audioPlatform = _FakeAmbientAudioPlatform(
      prepareCompleter: prepareCompleter,
    );
    final service = AmbientAudioService.withPlatform(audioPlatform);

    final playFuture = service.play();
    await Future<void>.delayed(Duration.zero);
    final disposeFuture = service.dispose();
    prepareCompleter.complete();

    await Future.wait([playFuture, disposeFuture]);

    expect(service.state.status, AmbientAudioStatus.disposed);
    expect(audioPlatform.startCount, 0);
    expect(audioPlatform.disposeCount, 1);
  });

  test('current playback errors are notified and rethrown', () async {
    final error = StateError('decode failed');
    final audioPlatform = _FakeAmbientAudioPlatform(prepareError: error);
    final service = AmbientAudioService.withPlatform(audioPlatform);

    await expectLater(service.play(), throwsA(same(error)));

    expect(service.state.status, AmbientAudioStatus.error);
    expect(service.state.error, same(error));
    expect(audioPlatform.startCount, 0);

    await service.dispose();
  });
}

class _FakeAmbientAudioPlatform implements AmbientAudioPlatform {
  _FakeAmbientAudioPlatform({this.prepareCompleter, this.prepareError});

  final Completer<void>? prepareCompleter;
  final Object? prepareError;

  int activateCount = 0;
  int prepareCount = 0;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> activate() async {
    activateCount++;
  }

  @override
  Future<void> prepare() {
    prepareCount++;
    final error = prepareError;
    if (error != null) {
      return Future<void>.error(error);
    }
    return prepareCompleter?.future ?? Future<void>.value();
  }

  @override
  void startLoop() {
    startCount++;
  }

  @override
  void stop() {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}

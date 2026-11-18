import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/ambient_sound/provider/ambient_sound_provider.dart';
import '../features/ambient_sound/repository/ambient_sound_repository.dart';
import '../features/ambient_sound/service/ambient_audio_service.dart';
import '../features/furniture/provider/catalog_provider.dart';
import '../features/furniture/provider/placed_furniture_provider.dart';
import '../features/furniture/repository/placed_furniture_repository.dart';
import '../features/furniture/repository/purchased_furniture_repository.dart';
import '../features/letters/provider/read_letter_provider.dart';
import '../features/letters/provider/shizuku_provider.dart';
import '../features/letters/repository/read_letter_repository.dart';
import '../features/letters/repository/shizuku_repository.dart';
import '../features/room/presentation/room_page.dart';
import '../shared/provider/app_data_provider.dart';
import '../shared/provider/weather_provider.dart';
import '../shared/repository/app_date_repository.dart';
import '../shared/repository/weather_repository.dart';

class AmeTsuzuriApp extends StatelessWidget {
  const AmeTsuzuriApp({
    super.key,
    this.ambientSoundRepository,
    this.ambientAudioService,
    this.weatherRepository,
  });

  final AmbientSoundRepository? ambientSoundRepository;
  final AmbientAudioService? ambientAudioService;
  final WeatherRepository? weatherRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ReadLetterProvider(ReadLetterRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => ShizukuProvider(ShizukuRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppDateProvider(AppDateRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              WeatherProvider(weatherRepository ?? WeatherRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => AmbientSoundProvider(
            ambientSoundRepository ?? AmbientSoundRepository(),
            ambientAudioService ?? AmbientAudioService(),
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CatalogProvider(PurchasedFurnitureRepository())..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              PlacedFurnitureProvider(PlacedFurnitureRepository())..load(),
        ),
      ],
      child: const _AppLifecycle(
        child: MaterialApp(
          title: '雨つづり。',
          debugShowCheckedModeBanner: false,
          home: RoomPage(),
        ),
      ),
    );
  }
}

class _AppLifecycle extends StatefulWidget {
  const _AppLifecycle({required this.child});

  final Widget child;

  @override
  State<_AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends State<_AppLifecycle>
    with WidgetsBindingObserver {
  Timer? _dateRefreshTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => context.read<AppDateProvider>().refreshLocalDate(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        context.read<AppDateProvider>().refreshLocalDate();
        unawaited(context.read<AmbientSoundProvider>().updateVisibility(true));
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(context.read<AmbientSoundProvider>().updateVisibility(false));
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

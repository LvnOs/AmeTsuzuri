import 'dart:math' as math;

import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/service/letter_delivery_service.dart';
import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/room/presentation/prototype_controls.dart';
import 'package:ame_tsuzuri/features/room/presentation/prototype_reset_page.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/autumn_leaf_effect.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/shared/model/season_type.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _TutorialTarget { none, letter, bottle, bookshelf }

enum _TutorialMove { none, letterToBottle, bottleToBookshelf }

_TutorialTarget _resolveTutorialTarget({
  required bool areProvidersLoaded,
  required bool tutorialCompleted,
  required bool isTutorialRead,
  required bool hasTutorialLetterInRoom,
  required bool hasOpenedTutorialBottle,
  required bool hasPurchasedFurniture,
  required bool hasPlacedFurniture,
}) {
  if (!areProvidersLoaded || tutorialCompleted) {
    return _TutorialTarget.none;
  }
  if (!isTutorialRead) {
    return hasTutorialLetterInRoom
        ? _TutorialTarget.letter
        : _TutorialTarget.none;
  }
  if (hasPlacedFurniture) {
    return _TutorialTarget.bookshelf;
  }
  if (!hasOpenedTutorialBottle && !hasPurchasedFurniture) {
    return _TutorialTarget.bottle;
  }
  return _TutorialTarget.none;
}

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, this.letterRepository, this.furnitureRepository});

  final LetterRepository? letterRepository;
  final FurnitureRepository? furnitureRepository;

  static const String _tutorialLetterId = 'tutorial_001';

  static const double _designWidth = 390;
  static const double _designHeight = 700;

  // Outdoor composition tuning. Keep x/y in the -1.0 to 1.0 Alignment range.
  static const Alignment _outdoorAlignment = Alignment(0.02, -0.94);
  static const double _outdoorScale = 0.66;

  // Post composition tuning. Scale is relative to the room canvas width.
  static const double _postX = -0.50;
  static const double _postY = -0.35;

  static const Alignment _postAlignment = Alignment(_postX, _postY);
  static const double _postScale = 0.19;
  static const double _postTapAreaWidthScale = 0.16;
  static const double _postTapAreaHeightScale = 0.25;

  // Curtain composition tuning. Width is relative to the room canvas width.
  static const Alignment _curtainAlignment = Alignment(0, -0.83);
  static const double _curtainWidthScale = 0.91;
  static const double _curtainHeightScale = 1.3;

  // Shared placement values for the bottle and its future water layer.
  static const Alignment _bottleAlignment = Alignment(0.58, -0.18);
  static const double _bottleScale = 0.13;

  // Vase composition tuning. Scale is relative to the room canvas width.
  static const Alignment _vaseAlignment = Alignment(0.33, -0.16);
  static const double _vaseScale = 0.091;

  // Flower composition tuning. Scale is relative to the room canvas width.
  static const Alignment _flowerAlignment = Alignment(0.34, -0.26);
  static const double _flowerScale = 0.13;

  // Letter composition tuning. Scale is relative to the room canvas width.
  static const Alignment _letterAlignment = Alignment(0, 0.07);
  static const double _letterScale = 0.22;
  static const double _letterAspectRatio = 460 / 307;

  // Desk-left furniture tuning for the 390 x 700 Room composition.
  static const String _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';
  static const Alignment _deskSurfaceLeftFurnitureAlignment = Alignment(
    -0.65,
    0.02,
  );
  static const double _deskSurfaceLeftFurnitureScale = 0.25;
  static const Map<String, double> _deskSurfaceLeftScaleCorrections = {
    'wooden_mug': 1,
    'ink_bottle': 0.9,
    'wooden_fox_figure': 1.05,
  };

  // Desk-right furniture tuning for the 390 x 700 Room composition.
  static const String _deskSurfaceRightSlotId =
      'living_room_desk_surface_right';
  static const Alignment _deskSurfaceRightFurnitureAlignment = Alignment(
    0.70,
    0.02,
  );
  static const double _deskSurfaceRightFurnitureScale = 0.25;
  static const Map<String, double> _deskSurfaceRightScaleCorrections = {
    'wooden_mug': 1,
    'ink_bottle': 0.9,
    'wooden_fox_figure': 1.05,
  };

  // Window-shelf furniture tuning for the 390 x 700 Room composition.
  static const String _windowShelfDecorSlotId =
      'living_room_window_shelf_decor';
  static const Alignment _windowShelfDecorFurnitureAlignment = Alignment(
    -0.55,
    -0.15,
  );
  static const double _windowShelfDecorFurnitureScale = 0.16;
  static const Set<String> _windowShelfDecorFurnitureIds = {
    'small_houseplant',
    'wooden_bird_figure',
    'small_glass_ornament',
  };
  static const Map<String, double> _windowShelfDecorScaleCorrections = {
    'small_houseplant': 1,
    'wooden_bird_figure': 0.85,
    'small_glass_ornament': 0.78,
  };

  // Hanging furniture tuning for the 390 x 700 Room composition.
  static const String _windowHangingDecorSlotId =
      'living_room_window_hanging_decor';
  static const Alignment _windowHangingDecorFurnitureAlignment = Alignment(
    0.57,
    -0.93,
  );
  static const double _windowHangingDecorFurnitureScale = 0.18;
  static const Set<String> _windowHangingDecorFurnitureIds = {
    'wind_chime',
    'teru_teru_bozu',
    'moon_mobile',
  };
  static const Map<String, double> _windowHangingDecorScaleCorrections = {
    'wind_chime': 0.9,
    'teru_teru_bozu': 0.88,
    'moon_mobile': 0.92,
  };

  // Arrival animation tuning. Defaults follow the existing post and letter.
  static const Duration _arrivalAnimationDuration = Duration(
    milliseconds: 4350,
  );
  static const double _arrivalDelayEnd = 800 / 4350;
  static const double _arrivalGlowEnd = 2600 / 4350;
  static const double _arrivalMoveEnd = 4000 / 4350;
  static const double _postArrivalGlowXOffset = -0.13;
  static const double _postArrivalGlowYOffset = -0.13;
  static const Alignment _postArrivalGlowAlignment = Alignment(
    _postX + _postArrivalGlowXOffset,
    _postY + _postArrivalGlowYOffset,
  );
  static const double _postArrivalGlowScale = 0.32;
  static const double _postArrivalGlowMinimumOpacity = 0.06;
  static const double _postArrivalGlowMaximumOpacity = 0.45;
  static const Alignment _arrivalLightStartAlignment = Alignment(
    _postX + _postArrivalGlowXOffset + 0.25,
    _postY + _postArrivalGlowYOffset + 0.07,
  );
  static const Alignment _arrivalLightEndAlignment = _letterAlignment;

  // Tutorial target glow tuning. Scale is relative to the room canvas width.
  static const Duration _tutorialGlowDuration = Duration(milliseconds: 1300);
  static const double _tutorialGlowMinimumOpacity = 0.14;
  static const double _tutorialLetterGlowMaximumOpacity = 0.48;
  static const double _tutorialBottleGlowMaximumOpacity = 0.60;
  static const double _tutorialBookshelfGlowMaximumOpacity = 0.53;
  static const List<Color> _tutorialGlowColors = [
    Color(0xFFFFFAEC),
    Color(0xCCF8DFA0),
    Color(0x66D89A45),
    Color(0x00C47A2C),
  ];
  static const List<Color> _tutorialBottleGlowColors = [
    Color(0xFFFFFFFF),
    Color(0xE6FFE7AC),
    Color(0x80E4A34A),
    Color(0x00C8792B),
  ];
  static const double _tutorialLetterGlowScale = 0.30;
  static const Alignment _tutorialBottleGlowAlignment = Alignment(0.66, -0.18);
  static const double _tutorialBottleGlowScale = 0.23;
  static const Alignment _tutorialBookshelfMoveAlignment = Alignment(
    -0.90,
    0.25,
  );
  static const Alignment _tutorialBookshelfGlowAlignment = Alignment(
    -1.25,
    0.25,
  );
  static const double _tutorialBookshelfGlowScale = 0.27;
  static const Duration _tutorialMoveDuration = Duration(milliseconds: 1300);
  static const double _tutorialMoveLightScale = 0.055;
  static const double _tutorialMoveLightMaximumOpacity = 0.74;
  static const List<Color> _tutorialMoveLightColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF0C2),
    Color(0xB8E6A552),
    Color(0x00C98732),
  ];

  @visibleForTesting
  static Duration get tutorialGlowDurationForTesting => _tutorialGlowDuration;

  @visibleForTesting
  static Duration get tutorialMoveDurationForTesting => _tutorialMoveDuration;

  @visibleForTesting
  static double get tutorialGlowMinimumOpacityForTesting =>
      _tutorialGlowMinimumOpacity;

  @visibleForTesting
  static double get tutorialLetterGlowMaximumOpacityForTesting =>
      _tutorialLetterGlowMaximumOpacity;

  @visibleForTesting
  static double get tutorialBottleGlowMaximumOpacityForTesting =>
      _tutorialBottleGlowMaximumOpacity;

  @visibleForTesting
  static double get tutorialBookshelfGlowMaximumOpacityForTesting =>
      _tutorialBookshelfGlowMaximumOpacity;

  @visibleForTesting
  static List<Color> get tutorialGlowColorsForTesting => _tutorialGlowColors;

  @visibleForTesting
  static List<Color> get tutorialBottleGlowColorsForTesting =>
      _tutorialBottleGlowColors;

  @visibleForTesting
  static double get tutorialMoveLightScaleForTesting => _tutorialMoveLightScale;

  @visibleForTesting
  static double get tutorialMoveLightMaximumOpacityForTesting =>
      _tutorialMoveLightMaximumOpacity;

  @visibleForTesting
  static List<Color> get tutorialMoveLightColorsForTesting =>
      _tutorialMoveLightColors;

  @visibleForTesting
  static Alignment get tutorialBottleGlowAlignmentForTesting =>
      _tutorialBottleGlowAlignment;

  @visibleForTesting
  static Alignment get tutorialBookshelfGlowAlignmentForTesting =>
      _tutorialBookshelfGlowAlignment;

  @visibleForTesting
  static Alignment get tutorialLetterAlignmentForTesting => _letterAlignment;

  @visibleForTesting
  static Alignment get tutorialBottleAlignmentForTesting => _bottleAlignment;

  @visibleForTesting
  static Alignment get tutorialBookshelfMoveAlignmentForTesting =>
      _tutorialBookshelfMoveAlignment;

  @visibleForTesting
  static double tutorialMovingLightOpacityForTesting(double progress) =>
      _tutorialMovingLightOpacity(progress);

  // Chair composition tuning. Scale is relative to the room canvas width.
  static const Alignment _chairAlignment = Alignment(0, 0.72);
  static const double _chairScale = 0.47;
  static const String _chairSlotId = 'living_room_chair';
  static const Set<String> _chairFurnitureIds = {
    'wooden_chair',
    'cushioned_chair',
    'rocking_chair',
  };

  // Rug composition tuning. Width and height are independently adjustable.
  static const Alignment _rugAlignment = Alignment(0.25, 1.035);
  static const double _rugWidthScale = 0.800;
  static const double _rugHeightScale = 0.75;
  static const String _floorRugSlotId = 'living_room_floor_rug';

  @visibleForTesting
  static String resolveTutorialTargetForTesting({
    required bool areProvidersLoaded,
    required bool tutorialCompleted,
    required bool isTutorialRead,
    required bool hasTutorialLetterInRoom,
    required bool hasOpenedTutorialBottle,
    required bool hasPurchasedFurniture,
    required bool hasPlacedFurniture,
  }) {
    return _resolveTutorialTarget(
      areProvidersLoaded: areProvidersLoaded,
      tutorialCompleted: tutorialCompleted,
      isTutorialRead: isTutorialRead,
      hasTutorialLetterInRoom: hasTutorialLetterInRoom,
      hasOpenedTutorialBottle: hasOpenedTutorialBottle,
      hasPurchasedFurniture: hasPurchasedFurniture,
      hasPlacedFurniture: hasPlacedFurniture,
    ).name;
  }

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with TickerProviderStateMixin {
  static const Duration _weatherRetryDelay = Duration(milliseconds: 750);

  late final LetterRepository _letterRepository;
  late final Future<List<Furniture>> _furnituresFuture;
  final LetterDeliveryService _letterDeliveryService =
      const LetterDeliveryService();
  DateTime? _attemptedDeliveryDate;
  DateTime? _requestedWeatherDate;
  Future<void>? _requestedWeatherLoad;
  bool _isOpeningLetter = false;
  bool _isNavigatingFromRoom = false;
  bool _isArrivalAnimating = false;
  bool _isPrototypeOperationRunning = false;
  SeasonType? _outdoorSeasonOverride;
  late final AnimationController _arrivalController;
  late final AnimationController _tutorialGlowController;
  late final AnimationController _tutorialMoveController;
  _TutorialTarget _requestedTutorialTarget = _TutorialTarget.none;
  bool _isTutorialGlowSyncScheduled = false;
  _TutorialMove _tutorialMove = _TutorialMove.none;

  @override
  void initState() {
    super.initState();
    _letterRepository = widget.letterRepository ?? LetterRepository();
    _furnituresFuture = (widget.furnitureRepository ?? FurnitureRepository())
        .getAll();
    _arrivalController = AnimationController(
      vsync: this,
      duration: RoomPage._arrivalAnimationDuration,
    )..addStatusListener(_onArrivalAnimationStatusChanged);
    _tutorialGlowController = AnimationController(
      vsync: this,
      duration: RoomPage._tutorialGlowDuration,
    );
    _tutorialMoveController = AnimationController(
      vsync: this,
      duration: RoomPage._tutorialMoveDuration,
    )..addStatusListener(_onTutorialMoveStatusChanged);
  }

  @override
  void dispose() {
    _arrivalController
      ..removeStatusListener(_onArrivalAnimationStatusChanged)
      ..dispose();
    _tutorialGlowController.dispose();
    _tutorialMoveController
      ..removeStatusListener(_onTutorialMoveStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appDateProvider = context.watch<AppDateProvider>();
    final readLetterProvider = context.watch<ReadLetterProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final placedFurnitureProvider = context.watch<PlacedFurnitureProvider>();
    final weatherProvider = context.watch<WeatherProvider>();

    final deskSurfaceLeftFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage
              ._deskSurfaceLeftSlotId]
        : null;
    final deskSurfaceRightFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage
              ._deskSurfaceRightSlotId]
        : null;
    final windowShelfDecorFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage
              ._windowShelfDecorSlotId]
        : null;
    final windowHangingDecorFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage
              ._windowHangingDecorSlotId]
        : null;
    final floorRugFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage._floorRugSlotId]
        : null;
    final chairFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage._chairSlotId]
        : null;

    var showLetter = false;
    if (appDateProvider.isLoaded) {
      _scheduleWeatherLoad(_dateOnly(appDateProvider.today));
    }
    if (appDateProvider.isLoaded && readLetterProvider.isLoaded) {
      final today = _dateOnly(appDateProvider.today);
      showLetter = readLetterProvider.hasDeliveredLetterOn(today);
      if (!showLetter) {
        _scheduleDelivery(today);
      }
    }

    final tutorialTarget = _resolveTutorialTarget(
      areProvidersLoaded:
          readLetterProvider.isLoaded &&
          catalogProvider.isLoaded &&
          placedFurnitureProvider.isLoaded,
      tutorialCompleted: readLetterProvider.tutorialCompleted,
      isTutorialRead: readLetterProvider.readLetterIds.contains(
        RoomPage._tutorialLetterId,
      ),
      hasTutorialLetterInRoom:
          showLetter &&
          readLetterProvider.deliveredLetterIdOn(appDateProvider.today) ==
              RoomPage._tutorialLetterId,
      hasOpenedTutorialBottle: readLetterProvider.hasOpenedTutorialBottle,
      hasPurchasedFurniture: catalogProvider.purchasedFurnitureIds.isNotEmpty,
      hasPlacedFurniture: placedFurnitureProvider.placedFurnitureIds.isNotEmpty,
    );
    final visibleTutorialTarget =
        _isArrivalAnimating ||
            _tutorialMove != _TutorialMove.none ||
            _isNavigatingFromRoom
        ? _TutorialTarget.none
        : tutorialTarget;
    _scheduleTutorialGlowSync(visibleTutorialTarget);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: RoomPage._designWidth / RoomPage._designHeight,
            child: _RoomBackgroundLayers(
              season: _outdoorSeasonOverride ?? appDateProvider.currentSeason,
              showRain:
                  appDateProvider.isLoaded &&
                  weatherProvider.loadedDate ==
                      _dateOnly(appDateProvider.today) &&
                  weatherProvider.currentWeather == WeatherType.rain,
              hasDeliveredLetter: showLetter,
              isArrivalAnimating: _isArrivalAnimating,
              arrivalAnimation: _arrivalController,
              tutorialTarget: visibleTutorialTarget,
              tutorialGlowAnimation: _tutorialGlowController,
              tutorialMove: _tutorialMove,
              tutorialMoveAnimation: _tutorialMoveController,
              furnituresFuture: _furnituresFuture,
              deskSurfaceLeftFurnitureId: deskSurfaceLeftFurnitureId,
              deskSurfaceRightFurnitureId: deskSurfaceRightFurnitureId,
              windowShelfDecorFurnitureId: windowShelfDecorFurnitureId,
              windowHangingDecorFurnitureId: windowHangingDecorFurnitureId,
              floorRugFurnitureId: floorRugFurnitureId,
              chairFurnitureId: chairFurnitureId,
              onTapBottle: _onTapBottle,
              onTapBookshelf: _onTapBookshelf,
              onTapLetter: _onTapLetter,
              onTapPost: _onTapPost,
              isPrototypeOperationRunning: _isPrototypeOperationRunning,
              onMoveToNextDay: _moveToNextDay,
              onOutdoorSeasonChanged: _setOutdoorSeasonOverride,
              onResetPrototype: _confirmPrototypeReset,
            ),
          ),
        ),
      ),
    );
  }

  void _setOutdoorSeasonOverride(SeasonType? season) {
    setState(() => _outdoorSeasonOverride = season);
  }

  void _onTapPost() {
    if (_isArrivalAnimating) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ポストは、雨の中で静かに佇んでいます。')));
  }

  void _scheduleWeatherLoad(DateTime date) {
    if (_requestedWeatherDate == date) {
      return;
    }

    _requestedWeatherDate = date;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedWeatherDate != date) {
        return;
      }
      final load = context.read<WeatherProvider>().loadForDate(date);
      _requestedWeatherLoad = load;
      load.catchError((_) {
        // A later Room rebuild or the delivery retry can try this date again.
      });
    });
  }

  void _scheduleTutorialGlowSync(_TutorialTarget target) {
    _requestedTutorialTarget = target;
    if (_isTutorialGlowSyncScheduled) {
      return;
    }

    _isTutorialGlowSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isTutorialGlowSyncScheduled = false;
      if (!mounted) {
        return;
      }

      if (_requestedTutorialTarget == _TutorialTarget.none) {
        _tutorialGlowController
          ..stop()
          ..value = 0;
      } else if (!_tutorialGlowController.isAnimating) {
        _tutorialGlowController.repeat(reverse: true);
      }
    });
  }

  void _startTutorialLetterToBottleMove() {
    if (_tutorialMove != _TutorialMove.none || _isArrivalAnimating) {
      return;
    }

    setState(() => _tutorialMove = _TutorialMove.letterToBottle);
    _tutorialMoveController.forward(from: 0);
  }

  void _startTutorialBottleToBookshelfMove() {
    if (_tutorialMove != _TutorialMove.none || _isArrivalAnimating) {
      return;
    }

    setState(() => _tutorialMove = _TutorialMove.bottleToBookshelf);
    _tutorialMoveController.forward(from: 0);
  }

  void _onTutorialMoveStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _tutorialMove = _TutorialMove.none);
    }
  }

  void _scheduleDelivery(DateTime date) {
    if (_attemptedDeliveryDate == date) {
      return;
    }

    _attemptedDeliveryDate = date;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _deliverLetterFor(date);
    });
  }

  Future<void> _deliverLetterFor(DateTime date) async {
    if (!mounted) {
      return;
    }

    final appDateProvider = context.read<AppDateProvider>();
    final readLetterProvider = context.read<ReadLetterProvider>();
    final weatherProvider = context.read<WeatherProvider>();
    if (!appDateProvider.isLoaded ||
        !readLetterProvider.isLoaded ||
        _dateOnly(appDateProvider.today) != date ||
        readLetterProvider.hasDeliveredLetterOn(date)) {
      return;
    }

    try {
      final letters = await _letterRepository.getAll();
      if (!mounted ||
          _dateOnly(context.read<AppDateProvider>().today) != date ||
          readLetterProvider.hasDeliveredLetterOn(date)) {
        return;
      }

      if (!readLetterProvider.readLetterIds.contains(
        RoomPage._tutorialLetterId,
      )) {
        final tutorialLetter = _findLetterById(
          letters,
          RoomPage._tutorialLetterId,
        );
        if (tutorialLetter != null) {
          await _deliverAndAnimate(tutorialLetter.id, date);
          return;
        }
      }

      final didLoadWeather = await _loadWeatherForNormalDelivery(
        weatherProvider: weatherProvider,
        date: date,
      );
      if (!didLoadWeather) {
        return;
      }

      if (!mounted ||
          _dateOnly(context.read<AppDateProvider>().today) != date ||
          readLetterProvider.hasDeliveredLetterOn(date)) {
        return;
      }

      final currentWeather = weatherProvider.currentWeather;
      if (currentWeather == null) {
        return;
      }

      final normalLetters = letters
          .where((letter) => letter.id != RoomPage._tutorialLetterId)
          .toList();
      final letter = _letterDeliveryService.selectLetter(
        letters: normalLetters,
        currentSeason: context.read<AppDateProvider>().currentSeason,
        currentWeather: currentWeather,
        readLetterIds: readLetterProvider.readLetterIds,
      );
      if (letter == null) {
        return;
      }

      await _deliverAndAnimate(letter.id, date);
    } catch (_) {
      // Delivery is retried on a later Room rebuild or date change.
    }
  }

  Future<bool> _loadWeatherForNormalDelivery({
    required WeatherProvider weatherProvider,
    required DateTime date,
  }) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (weatherProvider.loadedDate != date) {
          final scheduledLoad = attempt == 0 && _requestedWeatherDate == date
              ? _requestedWeatherLoad
              : null;
          await (scheduledLoad ?? weatherProvider.loadForDate(date));
        }
        return true;
      } catch (_) {
        if (attempt == 1) {
          return false;
        }

        await Future<void>.delayed(_weatherRetryDelay);
        if (!_canContinueDeliveryFor(date)) {
          return false;
        }
      }
    }

    return false;
  }

  bool _canContinueDeliveryFor(DateTime date) {
    if (!mounted) {
      return false;
    }

    final appDateProvider = context.read<AppDateProvider>();
    final readLetterProvider = context.read<ReadLetterProvider>();
    return appDateProvider.isLoaded &&
        readLetterProvider.isLoaded &&
        _dateOnly(appDateProvider.today) == date &&
        !readLetterProvider.hasDeliveredLetterOn(date);
  }

  Future<void> _deliverAndAnimate(String letterId, DateTime date) async {
    final didDeliver = await context.read<ReadLetterProvider>().deliver(
      letterId,
      deliveredDate: date,
    );
    if (didDeliver && mounted) {
      _startArrivalAnimation();
    }
  }

  void _startArrivalAnimation() {
    setState(() => _isArrivalAnimating = true);
    _arrivalController.forward(from: 0);
  }

  void _onArrivalAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isArrivalAnimating = false);
    }
  }

  Future<void> _onTapLetter() async {
    if (_isOpeningLetter) {
      return;
    }

    _isOpeningLetter = true;
    try {
      final appDateProvider = context.read<AppDateProvider>();
      final readLetterProvider = context.read<ReadLetterProvider>();
      if (!appDateProvider.isLoaded || !readLetterProvider.isLoaded) {
        return;
      }

      final initialToday = _dateOnly(appDateProvider.today);
      final initialDeliveredLetterId = readLetterProvider.deliveredLetterIdOn(
        initialToday,
      );
      if (initialDeliveredLetterId == null) {
        return;
      }

      final shizukuProvider = context.read<ShizukuProvider>();
      if (!shizukuProvider.isLoaded) {
        await shizukuProvider.load();
      }
      if (!mounted || !shizukuProvider.isLoaded) {
        return;
      }

      final today = _dateOnly(context.read<AppDateProvider>().today);
      if (today != initialToday) {
        return;
      }
      final currentDeliveredLetterId = readLetterProvider.deliveredLetterIdOn(
        today,
      );
      if (currentDeliveredLetterId != initialDeliveredLetterId) {
        return;
      }
      final deliveredLetterId = initialDeliveredLetterId;
      final wasUnreadBeforeOpening = !readLetterProvider.readLetterIds.contains(
        deliveredLetterId,
      );
      final shouldMoveToBottleAfterReading =
          deliveredLetterId == RoomPage._tutorialLetterId &&
          wasUnreadBeforeOpening;

      final letters = await _letterRepository.getAll();
      if (!mounted ||
          _dateOnly(context.read<AppDateProvider>().today) != today ||
          readLetterProvider.deliveredLetterIdOn(today) != deliveredLetterId) {
        return;
      }

      Letter? deliveredLetter;
      for (final letter in letters) {
        if (letter.id == deliveredLetterId) {
          deliveredLetter = letter;
          break;
        }
      }
      if (deliveredLetter == null) {
        return;
      }

      if (!readLetterProvider.readLetterIds.contains(deliveredLetterId)) {
        try {
          await shizukuProvider.rewardForLetter(deliveredLetterId);
        } catch (_) {
          return;
        }

        try {
          await readLetterProvider.markAsRead(
            deliveredLetterId,
            receivedDate: today,
          );
        } catch (_) {
          try {
            await readLetterProvider.load();
          } catch (_) {
            // A later app load can synchronize the persisted state again.
          }
          return;
        }
      }

      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => LetterPage(letter: deliveredLetter!),
        ),
      );
      if (mounted &&
          shouldMoveToBottleAfterReading &&
          !context.read<ReadLetterProvider>().tutorialCompleted) {
        _startTutorialLetterToBottleMove();
      }
    } catch (_) {
      // Keep the delivered letter in the Room so the user can try again later.
    } finally {
      _isOpeningLetter = false;
    }
  }

  Future<void> _onTapBottle() async {
    if (_isNavigatingFromRoom) {
      return;
    }

    setState(() => _isNavigatingFromRoom = true);
    try {
      final readLetterProvider = context.read<ReadLetterProvider>();
      final catalogProvider = context.read<CatalogProvider>();
      final isTutorialGuideEligible =
          readLetterProvider.isLoaded &&
          catalogProvider.isLoaded &&
          readLetterProvider.readLetterIds.contains(
            RoomPage._tutorialLetterId,
          ) &&
          !readLetterProvider.hasOpenedTutorialBottle &&
          !readLetterProvider.tutorialCompleted &&
          catalogProvider.purchasedFurnitureIds.isEmpty;

      final showTutorialGuide = isTutorialGuideEligible
          ? await readLetterProvider.markTutorialBottleOpened()
          : false;
      if (!mounted) {
        return;
      }

      final didPlaceFurniture = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (context) =>
              CatalogPage(showTutorialGuide: showTutorialGuide),
        ),
      );
      if (mounted && didPlaceFurniture == true) {
        _onReturnFromCatalogAfterPlacement();
      }
    } catch (_) {
      // Keep the Room available so the tutorial action can be retried.
    } finally {
      if (mounted) {
        setState(() => _isNavigatingFromRoom = false);
      } else {
        _isNavigatingFromRoom = false;
      }
    }
  }

  void _onReturnFromCatalogAfterPlacement() {
    final readLetterProvider = context.read<ReadLetterProvider>();
    final catalogProvider = context.read<CatalogProvider>();
    final placedFurnitureProvider = context.read<PlacedFurnitureProvider>();
    if (readLetterProvider.isLoaded &&
        catalogProvider.isLoaded &&
        placedFurnitureProvider.isLoaded &&
        readLetterProvider.readLetterIds.contains(RoomPage._tutorialLetterId) &&
        !readLetterProvider.tutorialCompleted &&
        placedFurnitureProvider.placedFurnitureIds.isNotEmpty) {
      _startTutorialBottleToBookshelfMove();
    }
  }

  Future<void> _onTapBookshelf() async {
    if (_isNavigatingFromRoom) {
      return;
    }

    setState(() => _isNavigatingFromRoom = true);
    try {
      final readLetterProvider = context.read<ReadLetterProvider>();
      final shizukuProvider = context.read<ShizukuProvider>();
      final catalogProvider = context.read<CatalogProvider>();
      final placedFurnitureProvider = context.read<PlacedFurnitureProvider>();
      await Future.wait([
        if (!readLetterProvider.isLoaded) readLetterProvider.load(),
        if (!shizukuProvider.isLoaded) shizukuProvider.load(),
        if (!catalogProvider.isLoaded) catalogProvider.load(),
        if (!placedFurnitureProvider.isLoaded) placedFurnitureProvider.load(),
      ]);
      if (!mounted ||
          !readLetterProvider.isLoaded ||
          !shizukuProvider.isLoaded ||
          !catalogProvider.isLoaded ||
          !placedFurnitureProvider.isLoaded) {
        return;
      }

      final shouldCompleteTutorial =
          readLetterProvider.readLetterIds.contains(
            RoomPage._tutorialLetterId,
          ) &&
          placedFurnitureProvider.placedFurnitureIds.isNotEmpty &&
          !readLetterProvider.tutorialCompleted;
      if (shouldCompleteTutorial) {
        final shouldOpenBookshelf = await _showBookshelfTutorialGuide();
        if (shouldOpenBookshelf != true || !mounted) {
          return;
        }
        final completed = await readLetterProvider.completeTutorial();
        if (!mounted) {
          return;
        }
        if (!completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('チュートリアルの完了を保存できませんでした')),
          );
          return;
        }
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const BookshelfPage()),
      );
    } catch (_) {
      // Keep the Room available so the user can retry after a load failure.
    } finally {
      if (mounted) {
        setState(() => _isNavigatingFromRoom = false);
      } else {
        _isNavigatingFromRoom = false;
      }
    }
  }

  Future<bool?> _showBookshelfTutorialGuide() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('届いた手紙は、ここからいつでも読み返せます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('あとで'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('本棚を開く'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToNextDay() async {
    if (_isPrototypeOperationRunning) {
      return;
    }

    setState(() => _isPrototypeOperationRunning = true);
    try {
      await context.read<AppDateProvider>().moveToNextDay();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日付を進められませんでした')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPrototypeOperationRunning = false);
      }
    }
  }

  Future<void> _confirmPrototypeReset() async {
    if (_isPrototypeOperationRunning) {
      return;
    }

    setState(() => _isPrototypeOperationRunning = true);
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('最初からやり直しますか？'),
        content: const Text('手紙、雫、購入した家具、家具の配置が初期状態に戻ります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('最初から'),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }
    if (shouldReset != true) {
      setState(() => _isPrototypeOperationRunning = false);
      return;
    }

    try {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => PrototypeResetPage(
            letterRepository: _letterRepository,
            furnitureRepository: widget.furnitureRepository,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isPrototypeOperationRunning = false);
      }
    }
  }
}

class _RoomBackgroundLayers extends StatelessWidget {
  const _RoomBackgroundLayers({
    required this.season,
    required this.showRain,
    required this.hasDeliveredLetter,
    required this.isArrivalAnimating,
    required this.arrivalAnimation,
    required this.tutorialTarget,
    required this.tutorialGlowAnimation,
    required this.tutorialMove,
    required this.tutorialMoveAnimation,
    required this.furnituresFuture,
    required this.deskSurfaceLeftFurnitureId,
    required this.deskSurfaceRightFurnitureId,
    required this.windowShelfDecorFurnitureId,
    required this.windowHangingDecorFurnitureId,
    required this.floorRugFurnitureId,
    required this.chairFurnitureId,
    required this.onTapBottle,
    required this.onTapBookshelf,
    required this.onTapLetter,
    required this.onTapPost,
    required this.isPrototypeOperationRunning,
    required this.onMoveToNextDay,
    required this.onOutdoorSeasonChanged,
    required this.onResetPrototype,
  });

  final SeasonType season;
  final bool showRain;
  final bool hasDeliveredLetter;
  final bool isArrivalAnimating;
  final Animation<double> arrivalAnimation;
  final _TutorialTarget tutorialTarget;
  final Animation<double> tutorialGlowAnimation;
  final _TutorialMove tutorialMove;
  final Animation<double> tutorialMoveAnimation;
  final Future<List<Furniture>> furnituresFuture;
  final String? deskSurfaceLeftFurnitureId;
  final String? deskSurfaceRightFurnitureId;
  final String? windowShelfDecorFurnitureId;
  final String? windowHangingDecorFurnitureId;
  final String? floorRugFurnitureId;
  final String? chairFurnitureId;
  final VoidCallback onTapBottle;
  final VoidCallback onTapBookshelf;
  final VoidCallback onTapLetter;
  final VoidCallback onTapPost;
  final bool isPrototypeOperationRunning;
  final VoidCallback onMoveToNextDay;
  final ValueChanged<SeasonType?> onOutdoorSeasonChanged;
  final VoidCallback onResetPrototype;

  @override
  Widget build(BuildContext context) {
    final outdoorAssetPath = switch (season) {
      SeasonType.autumn => 'assets/images/room/outdoor_autumn.png',
      SeasonType.spring ||
      SeasonType.summer ||
      SeasonType.winter ||
      SeasonType.any => 'assets/images/room/outdoor_summer.png',
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: RoomPage._outdoorScale,
                alignment: RoomPage._outdoorAlignment,
                child: Image.asset(
                  outdoorAssetPath,
                  fit: BoxFit.cover,
                  alignment: RoomPage._outdoorAlignment,
                ),
              ),
              if (showRain) const RainOverlay(),
              if (season == SeasonType.autumn) const AutumnLeafEffect(),
              Align(
                alignment: RoomPage._postAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._postScale,
                  child: Image.asset(
                    'assets/images/room/post.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (isArrivalAnimating)
                _PostArrivalGlow(
                  animation: arrivalAnimation,
                  roomWidth: constraints.maxWidth,
                ),
              Image.asset(
                'assets/images/room/room_base.png',
                fit: BoxFit.cover,
              ),
              _FurnitureImageLayer(
                layerKey: const ValueKey('windowHangingDecorFurnitureLayer'),
                furnituresFuture: furnituresFuture,
                furnitureId: windowHangingDecorFurnitureId,
                roomWidth: constraints.maxWidth,
                alignment: RoomPage._windowHangingDecorFurnitureAlignment,
                scale: RoomPage._windowHangingDecorFurnitureScale,
                scaleCorrections: RoomPage._windowHangingDecorScaleCorrections,
                supportedFurnitureIds: RoomPage._windowHangingDecorFurnitureIds,
              ),
              if (tutorialTarget != _TutorialTarget.none)
                _TutorialTargetGlow(
                  key: ValueKey(
                    'tutorial${switch (tutorialTarget) {
                      _TutorialTarget.letter => 'Letter',
                      _TutorialTarget.bottle => 'Bottle',
                      _TutorialTarget.bookshelf => 'Bookshelf',
                      _TutorialTarget.none => '',
                    }}Glow',
                  ),
                  alignment: switch (tutorialTarget) {
                    _TutorialTarget.letter => RoomPage._letterAlignment,
                    _TutorialTarget.bottle =>
                      RoomPage._tutorialBottleGlowAlignment,
                    _TutorialTarget.bookshelf =>
                      RoomPage._tutorialBookshelfGlowAlignment,
                    _TutorialTarget.none => Alignment.center,
                  },
                  scale: switch (tutorialTarget) {
                    _TutorialTarget.letter => RoomPage._tutorialLetterGlowScale,
                    _TutorialTarget.bottle => RoomPage._tutorialBottleGlowScale,
                    _TutorialTarget.bookshelf =>
                      RoomPage._tutorialBookshelfGlowScale,
                    _TutorialTarget.none => 0,
                  },
                  maximumOpacity: switch (tutorialTarget) {
                    _TutorialTarget.letter =>
                      RoomPage._tutorialLetterGlowMaximumOpacity,
                    _TutorialTarget.bottle =>
                      RoomPage._tutorialBottleGlowMaximumOpacity,
                    _TutorialTarget.bookshelf =>
                      RoomPage._tutorialBookshelfGlowMaximumOpacity,
                    _TutorialTarget.none => 0,
                  },
                  colors: tutorialTarget == _TutorialTarget.bottle
                      ? RoomPage._tutorialBottleGlowColors
                      : null,
                  animation: tutorialGlowAnimation,
                  roomWidth: constraints.maxWidth,
                ),
              _RugLayer(
                furnituresFuture: furnituresFuture,
                furnitureId: floorRugFurnitureId,
                roomWidth: constraints.maxWidth,
              ),
              Align(
                alignment: RoomPage._curtainAlignment,
                child: Transform.scale(
                  scaleX: RoomPage._curtainWidthScale,
                  scaleY: RoomPage._curtainHeightScale,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Image.asset(
                      'assets/images/room/curtain.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              _FurnitureImageLayer(
                layerKey: const ValueKey('windowShelfDecorFurnitureLayer'),
                furnituresFuture: furnituresFuture,
                furnitureId: windowShelfDecorFurnitureId,
                roomWidth: constraints.maxWidth,
                alignment: RoomPage._windowShelfDecorFurnitureAlignment,
                scale: RoomPage._windowShelfDecorFurnitureScale,
                scaleCorrections: RoomPage._windowShelfDecorScaleCorrections,
                supportedFurnitureIds: RoomPage._windowShelfDecorFurnitureIds,
              ),
              _FurnitureImageLayer(
                layerKey: const ValueKey('deskSurfaceLeftFurnitureLayer'),
                furnituresFuture: furnituresFuture,
                furnitureId: deskSurfaceLeftFurnitureId,
                roomWidth: constraints.maxWidth,
                alignment: RoomPage._deskSurfaceLeftFurnitureAlignment,
                scale: RoomPage._deskSurfaceLeftFurnitureScale,
                scaleCorrections: RoomPage._deskSurfaceLeftScaleCorrections,
                supportedFurnitureIds: const {
                  'wooden_mug',
                  'ink_bottle',
                  'wooden_fox_figure',
                },
              ),
              _FurnitureImageLayer(
                layerKey: const ValueKey('deskSurfaceRightFurnitureLayer'),
                furnituresFuture: furnituresFuture,
                furnitureId: deskSurfaceRightFurnitureId,
                roomWidth: constraints.maxWidth,
                alignment: RoomPage._deskSurfaceRightFurnitureAlignment,
                scale: RoomPage._deskSurfaceRightFurnitureScale,
                scaleCorrections: RoomPage._deskSurfaceRightScaleCorrections,
                supportedFurnitureIds: const {
                  'wooden_mug',
                  'ink_bottle',
                  'wooden_fox_figure',
                },
              ),
              Align(
                alignment: RoomPage._bottleAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._bottleScale,
                  child: Image.asset(
                    'assets/images/room/bottle.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._flowerAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._flowerScale,
                  child: Image.asset(
                    'assets/images/room/flower_initial.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._vaseAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._vaseScale,
                  child: Image.asset(
                    'assets/images/room/vase.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              if (isArrivalAnimating)
                _ArrivalMovingLight(
                  animation: arrivalAnimation,
                  roomWidth: constraints.maxWidth,
                ),
              if (tutorialMove != _TutorialMove.none)
                _MovingLight(
                  lightKey: ValueKey(
                    tutorialMove == _TutorialMove.letterToBottle
                        ? 'tutorialLetterToBottleMovingLight'
                        : 'tutorialBottleToBookshelfMovingLight',
                  ),
                  startAlignment: tutorialMove == _TutorialMove.letterToBottle
                      ? RoomPage._letterAlignment
                      : RoomPage._bottleAlignment,
                  endAlignment: tutorialMove == _TutorialMove.letterToBottle
                      ? RoomPage._bottleAlignment
                      : RoomPage._tutorialBookshelfMoveAlignment,
                  animation: tutorialMoveAnimation,
                  roomWidth: constraints.maxWidth,
                  maximumOpacity: RoomPage._tutorialMoveLightMaximumOpacity,
                ),
              if (hasDeliveredLetter)
                Align(
                  key: const ValueKey('roomLetterLayer'),
                  alignment: RoomPage._letterAlignment,
                  child: AnimatedBuilder(
                    animation: arrivalAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: isArrivalAnimating
                            ? _letterArrivalOpacity(arrivalAnimation.value)
                            : 1,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: constraints.maxWidth * RoomPage._letterScale,
                      height:
                          constraints.maxWidth *
                          RoomPage._letterScale /
                          RoomPage._letterAspectRatio,
                      child: Image.asset(
                        'assets/images/room/letter.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              _ChairLayer(
                furnituresFuture: furnituresFuture,
                furnitureId: chairFurnitureId,
                roomWidth: constraints.maxWidth,
              ),
              Positioned(
                left: 0,
                top: constraints.maxHeight * 0.46,
                width: constraints.maxWidth * 0.17,
                height: constraints.maxHeight * 0.33,
                child: GestureDetector(
                  key: const ValueKey('bookshelfTapArea'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapBookshelf,
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: RoomPage._postAlignment,
                child: GestureDetector(
                  key: const ValueKey('postTapArea'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapPost,
                  child: SizedBox(
                    width:
                        constraints.maxWidth * RoomPage._postTapAreaWidthScale,
                    height:
                        constraints.maxWidth * RoomPage._postTapAreaHeightScale,
                  ),
                ),
              ),
              Align(
                alignment: RoomPage._bottleAlignment,
                child: GestureDetector(
                  key: const ValueKey('bottleTapArea'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapBottle,
                  child: SizedBox(
                    width: constraints.maxWidth * 0.17,
                    height: constraints.maxWidth * 0.24,
                  ),
                ),
              ),
              if (hasDeliveredLetter && !isArrivalAnimating)
                Align(
                  alignment: RoomPage._letterAlignment,
                  child: GestureDetector(
                    key: const ValueKey('letterTapArea'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onTapLetter,
                    child: SizedBox(
                      width: constraints.maxWidth * RoomPage._letterScale,
                      height:
                          constraints.maxWidth *
                          RoomPage._letterScale /
                          RoomPage._letterAspectRatio,
                      child: Image.asset(
                        'assets/images/room/letter.png',
                        fit: BoxFit.contain,
                        color: Colors.transparent,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              if (tutorialTarget == _TutorialTarget.bottle ||
                  tutorialTarget == _TutorialTarget.bookshelf)
                Positioned(
                  left: 16,
                  right: 16,
                  top: constraints.maxHeight * 0.10,
                  child: _TutorialRoomGuide(target: tutorialTarget),
                ),
              Positioned(
                right: 10,
                top: 10,
                child: PrototypeControls(
                  isRunning: isPrototypeOperationRunning,
                  onNextDay: onMoveToNextDay,
                  onOutdoorSeasonChanged: onOutdoorSeasonChanged,
                  onReset: onResetPrototype,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TutorialRoomGuide extends StatelessWidget {
  const _TutorialRoomGuide({required this.target});

  final _TutorialTarget target;

  @override
  Widget build(BuildContext context) {
    final message = switch (target) {
      _TutorialTarget.bottle => '瓶を開いてみましょう。',
      _TutorialTarget.bookshelf => '本棚を見てみましょう。',
      _TutorialTarget.none || _TutorialTarget.letter => '',
    };

    return IgnorePointer(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE6FFF8E8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x407A6548)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x263D342B),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                message,
                key: const ValueKey('tutorialRoomGuide'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4A4034),
                  fontSize: 14,
                  height: 1.4,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChairLayer extends StatelessWidget {
  const _ChairLayer({
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
  });

  static const String _fixedChairAssetPath = 'assets/images/room/chair.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null ||
        !RoomPage._chairFurnitureIds.contains(selectedId)) {
      return _buildChair(_fixedChairAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId &&
              furniture.slotIds.contains(RoomPage._chairSlotId)) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _fixedChairAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildChair(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildChair(String imagePath, {String? furnitureId}) {
    return Align(
      key: const ValueKey('roomChairLayer'),
      alignment: RoomPage._chairAlignment,
      child: SizedBox(
        width: roomWidth * RoomPage._chairScale,
        child: Image.asset(
          imagePath,
          key: ValueKey(
            furnitureId == null
                ? 'roomFixedChairImage'
                : 'roomFurnitureImage-$furnitureId',
          ),
          fit: BoxFit.contain,
          errorBuilder: furnitureId == null
              ? null
              : (context, error, stackTrace) => Image.asset(
                  _fixedChairAssetPath,
                  key: const ValueKey('roomFixedChairImage'),
                  fit: BoxFit.contain,
                ),
        ),
      ),
    );
  }
}

class _RugLayer extends StatelessWidget {
  const _RugLayer({
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
  });

  static const String _fixedRugAssetPath = 'assets/images/room/rug.png';

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null) {
      return _buildRug(_fixedRugAssetPath);
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        Furniture? selectedFurniture;
        for (final furniture in snapshot.data ?? const <Furniture>[]) {
          if (furniture.id == selectedId) {
            selectedFurniture = furniture;
            break;
          }
        }

        final imagePath = selectedFurniture == null
            ? _fixedRugAssetPath
            : 'assets/images/${selectedFurniture.imagePath}';
        return _buildRug(imagePath, furnitureId: selectedFurniture?.id);
      },
    );
  }

  Widget _buildRug(String imagePath, {String? furnitureId}) {
    return Align(
      key: const ValueKey('roomRugLayer'),
      alignment: RoomPage._rugAlignment,
      child: Transform.scale(
        scaleY: RoomPage._rugHeightScale,
        child: SizedBox(
          width: roomWidth * RoomPage._rugWidthScale,
          child: Image.asset(
            imagePath,
            key: ValueKey(
              furnitureId == null
                  ? 'roomFixedRugImage'
                  : 'roomFurnitureImage-$furnitureId',
            ),
            fit: BoxFit.contain,
            errorBuilder: furnitureId == null
                ? null
                : (context, error, stackTrace) => Image.asset(
                    _fixedRugAssetPath,
                    key: const ValueKey('roomFixedRugImage'),
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}

class _FurnitureImageLayer extends StatelessWidget {
  const _FurnitureImageLayer({
    required this.layerKey,
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
    required this.alignment,
    required this.scale,
    required this.scaleCorrections,
    required this.supportedFurnitureIds,
  });

  final Key layerKey;
  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;
  final Alignment alignment;
  final double scale;
  final Map<String, double> scaleCorrections;
  final Set<String> supportedFurnitureIds;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null || !supportedFurnitureIds.contains(selectedId)) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Furniture>>(
      future: furnituresFuture,
      builder: (context, snapshot) {
        final furnitures = snapshot.data;
        if (furnitures == null) {
          return const SizedBox.shrink();
        }

        Furniture? selectedFurniture;
        for (final furniture in furnitures) {
          if (furniture.id == selectedId) {
            selectedFurniture = furniture;
            break;
          }
        }
        if (selectedFurniture == null) {
          return const SizedBox.shrink();
        }

        final scaleCorrection = scaleCorrections[selectedId] ?? 1;
        return Align(
          key: layerKey,
          alignment: alignment,
          child: SizedBox(
            width: roomWidth * scale * scaleCorrection,
            child: Image.asset(
              'assets/images/${selectedFurniture.imagePath}',
              key: ValueKey('roomFurnitureImage-$selectedId'),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _TutorialTargetGlow extends StatelessWidget {
  const _TutorialTargetGlow({
    super.key,
    required this.alignment,
    required this.scale,
    required this.animation,
    required this.roomWidth,
    required this.maximumOpacity,
    this.colors,
  });

  final Alignment alignment;
  final double scale;
  final Animation<double> animation;
  final double roomWidth;
  final double maximumOpacity;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final curvedValue = Curves.easeInOut.transform(animation.value);
            final opacity =
                RoomPage._tutorialGlowMinimumOpacity +
                curvedValue *
                    (maximumOpacity - RoomPage._tutorialGlowMinimumOpacity);
            return Opacity(opacity: opacity, child: child);
          },
          child: Container(
            width: roomWidth * scale,
            height: roomWidth * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: colors ?? RoomPage._tutorialGlowColors,
                stops: const [0, 0.30, 0.68, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostArrivalGlow extends StatelessWidget {
  const _PostArrivalGlow({required this.animation, required this.roomWidth});

  final Animation<double> animation;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: RoomPage._postArrivalGlowAlignment,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final value = animation.value;
          if (value < RoomPage._arrivalDelayEnd ||
              value >= RoomPage._arrivalGlowEnd) {
            return const SizedBox.shrink();
          }
          final phaseProgress =
              ((value - RoomPage._arrivalDelayEnd) /
                      (RoomPage._arrivalGlowEnd - RoomPage._arrivalDelayEnd))
                  .clamp(0.0, 1.0);
          final pulse = math.pow(math.sin(phaseProgress * math.pi), 2);
          final opacity =
              RoomPage._postArrivalGlowMinimumOpacity +
              pulse *
                  (RoomPage._postArrivalGlowMaximumOpacity -
                      RoomPage._postArrivalGlowMinimumOpacity);
          return Opacity(opacity: opacity, child: child);
        },
        child: Container(
          key: const ValueKey('postArrivalGlow'),
          width: roomWidth * RoomPage._postArrivalGlowScale,
          height: roomWidth * RoomPage._postArrivalGlowScale,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFFFF4D6), Color(0x00FFF4D6)],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrivalMovingLight extends StatelessWidget {
  const _ArrivalMovingLight({required this.animation, required this.roomWidth});

  final Animation<double> animation;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    return _MovingLight(
      lightKey: const ValueKey('arrivalMovingLight'),
      startAlignment: RoomPage._arrivalLightStartAlignment,
      endAlignment: RoomPage._arrivalLightEndAlignment,
      animation: animation,
      roomWidth: roomWidth,
      maximumOpacity: 0.62,
      intervalStart: RoomPage._arrivalGlowEnd,
      intervalEnd: RoomPage._arrivalMoveEnd,
    );
  }
}

class _MovingLight extends StatelessWidget {
  const _MovingLight({
    this.lightKey,
    required this.startAlignment,
    required this.endAlignment,
    required this.animation,
    required this.roomWidth,
    required this.maximumOpacity,
    this.intervalStart = 0,
    this.intervalEnd = 1,
  });

  final Key? lightKey;
  final Alignment startAlignment;
  final Alignment endAlignment;
  final Animation<double> animation;
  final double roomWidth;
  final double maximumOpacity;
  final double intervalStart;
  final double intervalEnd;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          if (animation.value < intervalStart ||
              animation.value >= intervalEnd) {
            return const SizedBox.shrink();
          }
          final moveProgress =
              ((animation.value - intervalStart) /
                      (intervalEnd - intervalStart))
                  .clamp(0.0, 1.0);
          final curvedProgress = Curves.easeInOut.transform(moveProgress);
          final alignment = Alignment.lerp(
            startAlignment,
            endAlignment,
            curvedProgress,
          )!;
          final opacity =
              _tutorialMovingLightOpacity(moveProgress) * maximumOpacity;

          return Align(
            key: lightKey,
            alignment: alignment,
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: Container(
          width: roomWidth * RoomPage._tutorialMoveLightScale,
          height: roomWidth * RoomPage._tutorialMoveLightScale,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: RoomPage._tutorialMoveLightColors,
              stops: [0, 0.28, 0.64, 1],
            ),
          ),
        ),
      ),
    );
  }
}

double _tutorialMovingLightOpacity(double progress) {
  final normalizedProgress = progress.clamp(0.0, 1.0);
  if (normalizedProgress == 0 || normalizedProgress == 1) {
    return 0;
  }
  if (normalizedProgress <= 0.16) {
    return Curves.easeOutCubic.transform(normalizedProgress / 0.16);
  }
  if (normalizedProgress <= 0.78) {
    return 1;
  }
  return 1 - Curves.easeInCubic.transform((normalizedProgress - 0.78) / 0.22);
}

double _letterArrivalOpacity(double animationValue) {
  if (animationValue < RoomPage._arrivalMoveEnd) {
    return 0;
  }
  return Curves.easeIn.transform(
    ((animationValue - RoomPage._arrivalMoveEnd) /
            (1 - RoomPage._arrivalMoveEnd))
        .clamp(0.0, 1.0),
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

Letter? _findLetterById(List<Letter> letters, String letterId) {
  for (final letter in letters) {
    if (letter.id == letterId) {
      return letter;
    }
  }
  return null;
}

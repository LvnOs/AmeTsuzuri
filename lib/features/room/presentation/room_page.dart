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
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _TutorialTarget { none, letter, bottle, bookshelf }

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
  static const Duration _tutorialGlowDuration = Duration(milliseconds: 1800);
  static const double _tutorialGlowMinimumOpacity = 0.07;
  static const double _tutorialGlowMaximumOpacity = 0.36;
  static const double _tutorialBottleGlowMaximumOpacity = 0.55;
  static const List<Color> _tutorialBottleGlowColors = [
    Color(0xFFFFFFFF),
    Color(0xCCFFF4D6),
    Color(0x00FFF4D6),
  ];
  static const double _tutorialLetterGlowScale = 0.30;
  static const Alignment _tutorialBottleGlowAlignment = Alignment(0.66, -0.18);
  static const double _tutorialBottleGlowScale = 0.23;
  static const Alignment _tutorialBookshelfGlowAlignment = Alignment(
    -0.83,
    0.25,
  );
  static const double _tutorialBookshelfGlowScale = 0.27;
  static const Duration _tutorialMoveDuration = Duration(milliseconds: 1300);

  // Chair composition tuning. Scale is relative to the room canvas width.
  static const Alignment _chairAlignment = Alignment(0, 0.72);
  static const double _chairScale = 0.47;

  // Rug composition tuning. Width and height are independently adjustable.
  static const Alignment _rugAlignment = Alignment(0.53, 0.935);
  static const double _rugWidthScale = 0.898;
  static const double _rugHeightScale = 0.80;

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
  bool _isOpeningLetter = false;
  bool _isNavigatingFromRoom = false;
  bool _isArrivalAnimating = false;
  bool _isPrototypeOperationRunning = false;
  late final AnimationController _arrivalController;
  late final AnimationController _tutorialGlowController;
  late final AnimationController _tutorialMoveController;
  _TutorialTarget _requestedTutorialTarget = _TutorialTarget.none;
  bool _isTutorialGlowSyncScheduled = false;
  bool _isTutorialMoveAnimating = false;

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
    context.watch<WeatherProvider>();

    final deskSurfaceLeftFurnitureId = placedFurnitureProvider.isLoaded
        ? placedFurnitureProvider.placedFurnitureIds[RoomPage
              ._deskSurfaceLeftSlotId]
        : null;

    var showLetter = false;
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
        _isArrivalAnimating || _isTutorialMoveAnimating
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
              hasDeliveredLetter: showLetter,
              isArrivalAnimating: _isArrivalAnimating,
              arrivalAnimation: _arrivalController,
              tutorialTarget: visibleTutorialTarget,
              tutorialGlowAnimation: _tutorialGlowController,
              isTutorialMoveAnimating: _isTutorialMoveAnimating,
              tutorialMoveAnimation: _tutorialMoveController,
              furnituresFuture: _furnituresFuture,
              deskSurfaceLeftFurnitureId: deskSurfaceLeftFurnitureId,
              onTapBottle: _onTapBottle,
              onTapBookshelf: _onTapBookshelf,
              onTapLetter: _onTapLetter,
              isPrototypeOperationRunning: _isPrototypeOperationRunning,
              onMoveToNextDay: _moveToNextDay,
              onResetPrototype: _confirmPrototypeReset,
            ),
          ),
        ),
      ),
    );
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
    if (_isTutorialMoveAnimating || _isArrivalAnimating) {
      return;
    }

    setState(() => _isTutorialMoveAnimating = true);
    _tutorialMoveController.forward(from: 0);
  }

  void _onTutorialMoveStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _isTutorialMoveAnimating = false);
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
          await weatherProvider.loadForDate(date);
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

    _isNavigatingFromRoom = true;
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

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) =>
              CatalogPage(showTutorialGuide: showTutorialGuide),
        ),
      );
    } catch (_) {
      // Keep the Room available so the tutorial action can be retried.
    } finally {
      _isNavigatingFromRoom = false;
    }
  }

  Future<void> _onTapBookshelf() async {
    if (_isNavigatingFromRoom) {
      return;
    }

    _isNavigatingFromRoom = true;
    try {
      final readLetterProvider = context.read<ReadLetterProvider>();
      final shizukuProvider = context.read<ShizukuProvider>();
      await Future.wait([
        if (!readLetterProvider.isLoaded) readLetterProvider.load(),
        if (!shizukuProvider.isLoaded) shizukuProvider.load(),
      ]);
      if (!mounted ||
          !readLetterProvider.isLoaded ||
          !shizukuProvider.isLoaded) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (context) => const BookshelfPage()),
      );
    } catch (_) {
      // Keep the Room available so the user can retry after a load failure.
    } finally {
      _isNavigatingFromRoom = false;
    }
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
    required this.hasDeliveredLetter,
    required this.isArrivalAnimating,
    required this.arrivalAnimation,
    required this.tutorialTarget,
    required this.tutorialGlowAnimation,
    required this.isTutorialMoveAnimating,
    required this.tutorialMoveAnimation,
    required this.furnituresFuture,
    required this.deskSurfaceLeftFurnitureId,
    required this.onTapBottle,
    required this.onTapBookshelf,
    required this.onTapLetter,
    required this.isPrototypeOperationRunning,
    required this.onMoveToNextDay,
    required this.onResetPrototype,
  });

  final bool hasDeliveredLetter;
  final bool isArrivalAnimating;
  final Animation<double> arrivalAnimation;
  final _TutorialTarget tutorialTarget;
  final Animation<double> tutorialGlowAnimation;
  final bool isTutorialMoveAnimating;
  final Animation<double> tutorialMoveAnimation;
  final Future<List<Furniture>> furnituresFuture;
  final String? deskSurfaceLeftFurnitureId;
  final VoidCallback onTapBottle;
  final VoidCallback onTapBookshelf;
  final VoidCallback onTapLetter;
  final bool isPrototypeOperationRunning;
  final VoidCallback onMoveToNextDay;
  final VoidCallback onResetPrototype;

  @override
  Widget build(BuildContext context) {
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
                  'assets/images/room/outdoor_summer.png',
                  fit: BoxFit.cover,
                  alignment: RoomPage._outdoorAlignment,
                ),
              ),
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
                  maximumOpacity: tutorialTarget == _TutorialTarget.bottle
                      ? RoomPage._tutorialBottleGlowMaximumOpacity
                      : RoomPage._tutorialGlowMaximumOpacity,
                  colors: tutorialTarget == _TutorialTarget.bottle
                      ? RoomPage._tutorialBottleGlowColors
                      : null,
                  animation: tutorialGlowAnimation,
                  roomWidth: constraints.maxWidth,
                ),
              Align(
                alignment: RoomPage._rugAlignment,
                child: Transform.scale(
                  scaleY: RoomPage._rugHeightScale,
                  child: SizedBox(
                    width: constraints.maxWidth * RoomPage._rugWidthScale,
                    child: Image.asset(
                      'assets/images/room/rug.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
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
              _DeskSurfaceLeftFurniture(
                furnituresFuture: furnituresFuture,
                furnitureId: deskSurfaceLeftFurnitureId,
                roomWidth: constraints.maxWidth,
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
              if (isTutorialMoveAnimating)
                _MovingLight(
                  lightKey: const ValueKey('tutorialLetterToBottleMovingLight'),
                  startAlignment: RoomPage._letterAlignment,
                  endAlignment: RoomPage._bottleAlignment,
                  animation: tutorialMoveAnimation,
                  roomWidth: constraints.maxWidth,
                  maximumOpacity: 0.56,
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
              Align(
                alignment: RoomPage._chairAlignment,
                child: SizedBox(
                  width: constraints.maxWidth * RoomPage._chairScale,
                  child: Image.asset(
                    'assets/images/room/chair.png',
                    fit: BoxFit.contain,
                  ),
                ),
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
              Positioned(
                right: 10,
                top: 10,
                child: PrototypeControls(
                  isRunning: isPrototypeOperationRunning,
                  onNextDay: onMoveToNextDay,
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

class _DeskSurfaceLeftFurniture extends StatelessWidget {
  const _DeskSurfaceLeftFurniture({
    required this.furnituresFuture,
    required this.furnitureId,
    required this.roomWidth,
  });

  static const Set<String> _supportedFurnitureIds = {
    'wooden_mug',
    'ink_bottle',
    'wooden_fox_figure',
  };
  static const Map<String, double> _scaleCorrections = {
    'wooden_mug': 1,
    'ink_bottle': 0.9,
    'wooden_fox_figure': 1.05,
  };

  final Future<List<Furniture>> furnituresFuture;
  final String? furnitureId;
  final double roomWidth;

  @override
  Widget build(BuildContext context) {
    final selectedId = furnitureId;
    if (selectedId == null || !_supportedFurnitureIds.contains(selectedId)) {
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

        final scaleCorrection = _scaleCorrections[selectedId] ?? 1;
        return Align(
          key: const ValueKey('deskSurfaceLeftFurnitureLayer'),
          alignment: RoomPage._deskSurfaceLeftFurnitureAlignment,
          child: SizedBox(
            width:
                roomWidth *
                RoomPage._deskSurfaceLeftFurnitureScale *
                scaleCorrection,
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
                colors:
                    colors ??
                    const [
                      Color(0xFFFFF7E5),
                      Color(0x99FFF4D6),
                      Color(0x00FFF4D6),
                    ],
                stops: const [0, 0.42, 1],
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
              math.sin(moveProgress * math.pi).clamp(0.0, 1.0) * maximumOpacity;

          return Align(
            key: lightKey,
            alignment: alignment,
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: Container(
          width: roomWidth * 0.037,
          height: roomWidth * 0.037,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFFFF6DD), Color(0x00FFF6DD)],
            ),
          ),
        ),
      ),
    );
  }
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

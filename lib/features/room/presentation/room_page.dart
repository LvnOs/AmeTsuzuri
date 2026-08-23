import 'dart:math' as math;

import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/model/letter.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/service/letter_delivery_service.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, this.letterRepository});

  final LetterRepository? letterRepository;

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

  // Chair composition tuning. Scale is relative to the room canvas width.
  static const Alignment _chairAlignment = Alignment(0, 0.72);
  static const double _chairScale = 0.47;

  // Rug composition tuning. Width and height are independently adjustable.
  static const Alignment _rugAlignment = Alignment(0.53, 0.935);
  static const double _rugWidthScale = 0.898;
  static const double _rugHeightScale = 0.80;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with SingleTickerProviderStateMixin {
  late final LetterRepository _letterRepository;
  final LetterDeliveryService _letterDeliveryService =
      const LetterDeliveryService();
  DateTime? _attemptedDeliveryDate;
  bool _isOpeningLetter = false;
  bool _isArrivalAnimating = false;
  late final AnimationController _arrivalController;

  @override
  void initState() {
    super.initState();
    _letterRepository = widget.letterRepository ?? LetterRepository();
    _arrivalController = AnimationController(
      vsync: this,
      duration: RoomPage._arrivalAnimationDuration,
    )..addStatusListener(_onArrivalAnimationStatusChanged);
  }

  @override
  void dispose() {
    _arrivalController
      ..removeStatusListener(_onArrivalAnimationStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appDateProvider = context.watch<AppDateProvider>();
    final readLetterProvider = context.watch<ReadLetterProvider>();
    context.watch<WeatherProvider>();

    var showLetter = false;
    if (appDateProvider.isLoaded && readLetterProvider.isLoaded) {
      final today = _dateOnly(appDateProvider.today);
      showLetter = readLetterProvider.hasDeliveredLetterOn(today);
      if (!showLetter) {
        _scheduleDelivery(today);
      }
    }

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
              onTapLetter: _onTapLetter,
            ),
          ),
        ),
      ),
    );
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

      try {
        if (weatherProvider.loadedDate != date) {
          await weatherProvider.loadForDate(date);
        }
      } catch (_) {
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
    final appDateProvider = context.read<AppDateProvider>();
    final readLetterProvider = context.read<ReadLetterProvider>();
    final shizukuProvider = context.read<ShizukuProvider>();
    if (!appDateProvider.isLoaded ||
        !readLetterProvider.isLoaded ||
        !shizukuProvider.isLoaded ||
        _isOpeningLetter) {
      return;
    }

    final today = _dateOnly(appDateProvider.today);
    final deliveredLetterId = readLetterProvider.deliveredLetterIdOn(today);
    if (deliveredLetterId == null) {
      return;
    }

    _isOpeningLetter = true;
    try {
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
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => LetterPage(letter: deliveredLetter!),
        ),
      );
    } catch (_) {
      // Keep the delivered letter in the Room so the user can try again later.
    } finally {
      _isOpeningLetter = false;
    }
  }
}

class _RoomBackgroundLayers extends StatelessWidget {
  const _RoomBackgroundLayers({
    required this.hasDeliveredLetter,
    required this.isArrivalAnimating,
    required this.arrivalAnimation,
    required this.onTapLetter,
  });

  final bool hasDeliveredLetter;
  final bool isArrivalAnimating;
  final Animation<double> arrivalAnimation;
  final VoidCallback onTapLetter;

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
            ],
          ),
        );
      },
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
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        if (value < RoomPage._arrivalGlowEnd ||
            value >= RoomPage._arrivalMoveEnd) {
          return const SizedBox.shrink();
        }
        final moveProgress =
            ((value - RoomPage._arrivalGlowEnd) /
                    (RoomPage._arrivalMoveEnd - RoomPage._arrivalGlowEnd))
                .clamp(0.0, 1.0);
        final curvedProgress = Curves.easeInOut.transform(moveProgress);
        final alignment = Alignment.lerp(
          RoomPage._arrivalLightStartAlignment,
          RoomPage._arrivalLightEndAlignment,
          curvedProgress,
        )!;
        final opacity = math.sin(moveProgress * math.pi).clamp(0.0, 1.0) * 0.62;

        return Align(
          alignment: alignment,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: Container(
        key: const ValueKey('arrivalMovingLight'),
        width: roomWidth * 0.037,
        height: roomWidth * 0.037,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Color(0xFFFFF6DD), Color(0x00FFF6DD)],
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

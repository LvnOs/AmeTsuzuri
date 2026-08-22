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

  static const double _designWidth = 390;
  static const double _designHeight = 700;

  // Outdoor composition tuning. Keep x/y in the -1.0 to 1.0 Alignment range.
  static const Alignment _outdoorAlignment = Alignment(0.02, -0.94);
  static const double _outdoorScale = 0.66;

  // Post composition tuning. Scale is relative to the room canvas width.
  static const Alignment _postAlignment = Alignment(-0.50, -0.35);
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

class _RoomPageState extends State<RoomPage> {
  late final LetterRepository _letterRepository;
  final LetterDeliveryService _letterDeliveryService =
      const LetterDeliveryService();
  DateTime? _attemptedDeliveryDate;
  bool _isOpeningLetter = false;

  @override
  void initState() {
    super.initState();
    _letterRepository = widget.letterRepository ?? LetterRepository();
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
              showLetter: showLetter,
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

    try {
      final letters = await _letterRepository.getAll();
      if (!mounted ||
          _dateOnly(context.read<AppDateProvider>().today) != date ||
          readLetterProvider.hasDeliveredLetterOn(date)) {
        return;
      }

      final letter = _letterDeliveryService.selectLetter(
        letters: letters,
        currentSeason: context.read<AppDateProvider>().currentSeason,
        currentWeather: currentWeather,
        readLetterIds: readLetterProvider.readLetterIds,
      );
      if (letter == null) {
        return;
      }

      await readLetterProvider.deliver(letter.id, deliveredDate: date);
    } catch (_) {
      // Delivery is retried on a later Room rebuild or date change.
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
    required this.showLetter,
    required this.onTapLetter,
  });

  final bool showLetter;
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
              if (showLetter)
                Align(
                  key: const ValueKey('roomLetterLayer'),
                  alignment: RoomPage._letterAlignment,
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
              if (showLetter)
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

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

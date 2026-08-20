import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/service/letter_delivery_service.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/shared/provider/weather_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/rain_overlay.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/bottle_progress.dart';
import 'package:ame_tsuzuri/shared/model/weather_type.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key, this.letterRepository});

  final LetterRepository? letterRepository;

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  static const Map<String, _SlotLayout> _slotLayouts = {
    'living_room_desk_surface_left': _SlotLayout(0.61, 0.48, 0.07, 0.12),
    'living_room_desk_surface_center': _SlotLayout(0.69, 0.48, 0.07, 0.12),
    'living_room_desk_surface_right': _SlotLayout(0.77, 0.48, 0.07, 0.12),
    'living_room_desk_surface_front': _SlotLayout(0.69, 0.57, 0.08, 0.12),
    'living_room_desk_surface_back': _SlotLayout(0.69, 0.43, 0.08, 0.12),
    'living_room_bookshelf_top_left': _SlotLayout(0.07, 0.19, 0.08, 0.15),
    'living_room_bookshelf_top_right': _SlotLayout(0.16, 0.19, 0.08, 0.15),
    'living_room_bookshelf_bottom_left': _SlotLayout(0.07, 0.47, 0.08, 0.15),
    'living_room_bookshelf_bottom_right': _SlotLayout(0.16, 0.47, 0.08, 0.15),
    'living_room_window_vase': _SlotLayout(0.61, 0.35, 0.07, 0.18),
    'living_room_window_shelf_decor': _SlotLayout(0.54, 0.43, 0.07, 0.13),
    'living_room_window_hanging_decor': _SlotLayout(0.49, 0.12, 0.08, 0.16),
    'living_room_window_curtain': _SlotLayout(0.29, 0.05, 0.38, 0.56),
    'living_room_lamp': _SlotLayout(0.85, 0.47, 0.09, 0.30),
    'living_room_floor_rug': _SlotLayout(0.43, 0.72, 0.30, 0.20),
    'living_room_chair': _SlotLayout(0.73, 0.65, 0.13, 0.28),
  };

  final FurnitureRepository _furnitureRepository = FurnitureRepository();

  late final Future<List<Furniture>> _furnituresFuture;
  late final LetterRepository _letterRepository;
  final LetterDeliveryService _letterDeliveryService =
      const LetterDeliveryService();

  String _selectedArea = '机や本棚など、気になる場所をタップしてみてください';
  bool _isOpeningLetter = false;
  DateTime? _requestedWeatherDate;
  ShizukuProvider? _observedShizukuProvider;
  int? _previousBottleRecordCount;
  bool _showFullBottle = false;
  Timer? _fullBottleTimer;

  @override
  void initState() {
    super.initState();

    _furnituresFuture = _furnitureRepository.getAll();
    _letterRepository = widget.letterRepository ?? LetterRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shizukuProvider = context.read<ShizukuProvider>();
    if (!identical(_observedShizukuProvider, shizukuProvider)) {
      _observedShizukuProvider?.removeListener(_onShizukuChanged);
      _observedShizukuProvider = shizukuProvider;
      _previousBottleRecordCount = shizukuProvider.bottleRecordCount;
      shizukuProvider.addListener(_onShizukuChanged);
    }

    final appDateProvider = context.watch<AppDateProvider>();
    if (!appDateProvider.isLoaded) {
      return;
    }

    final today = _dateOnly(appDateProvider.today);
    if (_requestedWeatherDate == today) {
      return;
    }

    _requestedWeatherDate = today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _requestedWeatherDate != today) {
        return;
      }
      context.read<WeatherProvider>().loadForDate(today).catchError((_) {
        // Weather is optional. A later date change or desk tap retries.
      });
    });
  }

  void _onShizukuChanged() {
    final provider = _observedShizukuProvider;
    if (provider == null) {
      return;
    }

    final previousCount = _previousBottleRecordCount;
    final currentCount = provider.bottleRecordCount;
    _previousBottleRecordCount = currentCount;

    if (previousCount == null ||
        currentCount != previousCount + 1 ||
        currentCount % 30 != 0) {
      return;
    }

    _fullBottleTimer?.cancel();
    if (mounted) {
      setState(() => _showFullBottle = true);
    }
    _fullBottleTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() => _showFullBottle = false);
      }
    });
  }

  @override
  void dispose() {
    _fullBottleTimer?.cancel();
    _observedShizukuProvider?.removeListener(_onShizukuChanged);
    super.dispose();
  }

  void _onAreaTapped(String areaName) {
    setState(() {
      _selectedArea = '$areaNameをタップしました';
    });

    debugPrint('$areaName tapped');
  }

  // 窓の操作
  void onTapWindow() {
    _onAreaTapped('窓');
  }

  // 本棚ページへの遷移
  void _onTapBookshelf() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const BookshelfPage()),
    );
  }

  // 手紙ページへの遷移
  Future<void> _onTapDesk() async {
    final readLetterProvider = context.read<ReadLetterProvider>();
    final shizukuProvider = context.read<ShizukuProvider>();
    final appDateProvider = context.read<AppDateProvider>();
    final weatherProvider = context.read<WeatherProvider>();

    if (!readLetterProvider.isLoaded ||
        !shizukuProvider.isLoaded ||
        !appDateProvider.isLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('読み込み中です')));
      return;
    }

    if (_isOpeningLetter) {
      return;
    }

    _isOpeningLetter = true;

    try {
      final today = appDateProvider.today;

      if (readLetterProvider.hasReceivedLetterOn(today)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('今日の手紙はもう受け取りました')));
        return;
      }

      try {
        if (weatherProvider.loadedDate != _dateOnly(today)) {
          await weatherProvider.loadForDate(today);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('天候の読み込みに失敗しました')));
        }
        return;
      }

      if (!mounted) {
        return;
      }

      final currentWeather = weatherProvider.currentWeather;
      if (currentWeather == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('今日の天候を確認できませんでした')));
        return;
      }

      final letters = await _letterRepository.getAll();
      final letter = _letterDeliveryService.selectLetter(
        letters: letters,
        currentSeason: appDateProvider.currentSeason,
        currentWeather: currentWeather,
        readLetterIds: readLetterProvider.readLetterIds,
      );

      if (!mounted) {
        return;
      }

      if (letter == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('今日の手紙はまだ届いていません')));
        return;
      }

      try {
        await shizukuProvider.rewardForLetter(letter.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('雫の受け取りに失敗しました')));
        }
        return;
      }

      try {
        await readLetterProvider.markAsRead(letter.id, receivedDate: today);
      } catch (_) {
        try {
          await readLetterProvider.load();
        } catch (_) {
          // 次回起動時の初期ロードでも永続状態と再同期される。
        }

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('手紙の保存に失敗しました')));
        }
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => LetterPage(letter: letter),
        ),
      );
    } finally {
      _isOpeningLetter = false;
    }
  }

  // 目録ページへの遷移
  void _onTapCatalog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const CatalogPage()));
  }

  Future<void> _resetPrototypeData() async {
    final readLetterProvider = context.read<ReadLetterProvider>();
    final shizukuProvider = context.read<ShizukuProvider>();
    final appDateProvider = context.read<AppDateProvider>();
    final catalogProvider = context.read<CatalogProvider>();
    final placedFurnitureProvider = context.read<PlacedFurnitureProvider>();

    if (!readLetterProvider.isLoaded ||
        !shizukuProvider.isLoaded ||
        !appDateProvider.isLoaded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('読み込み中です')));
      return;
    }

    await readLetterProvider.reset();
    await shizukuProvider.reset();
    await catalogProvider.reset();
    await placedFurnitureProvider.reset();
    await appDateProvider.startPrototypePeriod();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('テストデータをリセットしました')));
  }

  @override
  Widget build(BuildContext context) {
    final appDateProvider = context.watch<AppDateProvider>();
    final readLetterProvider = context.watch<ReadLetterProvider>();
    final placedFurnitureIds = context
        .watch<PlacedFurnitureProvider>()
        .placedFurnitureIds;
    final weatherProvider = context.watch<WeatherProvider>();
    final shizukuProvider = context.watch<ShizukuProvider>();
    final isRoomReady =
        appDateProvider.isLoaded &&
        readLetterProvider.isLoaded &&
        shizukuProvider.isLoaded;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FutureBuilder<List<Furniture>>(
                    future: _furnituresFuture,
                    builder: (context, snapshot) {
                      return _buildRoom(
                        placedFurnitureIds,
                        snapshot.data ?? [],
                        weatherProvider.currentWeather,
                        shizukuProvider.currentBottleProgress,
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildMessageArea(isRoomReady),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom(
    Map<String, String> placedFurnitureIds,
    List<Furniture> furnitures,
    WeatherType? weather,
    int bottleProgress,
  ) {
    final furnitureById = {
      for (final furniture in furnitures) furniture.id: furniture,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            if (weather == WeatherType.rain) const RainOverlay(),
            ..._buildPlacedFurniture(
              placedFurnitureIds,
              furnitureById,
              constraints,
            ),

            Positioned(
              left: constraints.maxWidth * 0.69,
              top: constraints.maxHeight * 0.315,
              width: constraints.maxWidth * 0.105,
              height: constraints.maxHeight * 0.28,
              child: BottleProgress(
                progress: bottleProgress,
                showFullState: _showFullBottle,
              ),
            ),

            // 窓
            _buildTapArea(
              name: '窓',
              left: constraints.maxWidth * 0.30,
              top: constraints.maxHeight * 0.06,
              width: constraints.maxWidth * 0.36,
              height: constraints.maxHeight * 0.54,
              color: Colors.blue,
              onTap: onTapWindow,
            ),

            // 本棚
            _buildTapArea(
              name: '本棚',
              left: constraints.maxWidth * 0.055,
              top: constraints.maxHeight * 0.10,
              width: constraints.maxWidth * 0.205,
              height: constraints.maxHeight * 0.72,
              color: Colors.green,
              onTap: _onTapBookshelf,
            ),

            // 机
            _buildTapArea(
              key: const ValueKey('deskTapArea'),
              name: '机',
              left: constraints.maxWidth * 0.60,
              top: constraints.maxHeight * 0.53,
              width: constraints.maxWidth * 0.265,
              height: constraints.maxHeight * 0.42,
              color: Colors.orange,
              onTap: _onTapDesk,
            ),

            // 瓶
            _buildTapArea(
              name: '瓶',
              left: constraints.maxWidth * 0.69,
              top: constraints.maxHeight * 0.315,
              width: constraints.maxWidth * 0.105,
              height: constraints.maxHeight * 0.28,
              color: Colors.yellow,
              onTap: _onTapCatalog,
            ),

            // デバッグ用ボタン
            _buildDebugButton(),
          ],
        );
      },
    );
  }

  List<Widget> _buildPlacedFurniture(
    Map<String, String> placedFurnitureIds,
    Map<String, Furniture> furnitureById,
    BoxConstraints constraints,
  ) {
    final widgets = <Widget>[];

    for (final entry in placedFurnitureIds.entries) {
      final layout = _slotLayouts[entry.key];
      final furniture = furnitureById[entry.value];

      if (layout == null || furniture == null) {
        continue;
      }

      widgets.add(
        Positioned(
          left: constraints.maxWidth * layout.left,
          top: constraints.maxHeight * layout.top,
          width: constraints.maxWidth * layout.width,
          height: constraints.maxHeight * layout.height,
          child: Image.asset(
            'assets/images/${furniture.imagePath}',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildFurniturePlaceholder(furniture.name);
            },
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFurniturePlaceholder(String furnitureName) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD8C9AE).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xFF6B5A45)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chair_outlined),
            Text(furnitureName, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildTapArea({
    Key? key,
    required String name,
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color,
    required VoidCallback onTap,
    bool showDebugArea = false,
  }) {
    return Positioned(
      key: key,
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: showDebugArea
              ? BoxDecoration(
                  color: color.withValues(alpha: 0.01),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                )
              : null,
          alignment: Alignment.center,
        ),
      ),
    );
  }

  Widget _buildMessageArea(bool isRoomReady) {
    final message = isRoomReady ? _selectedArea : '読み込み中です…';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF201F1C),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFE8E1D4), fontSize: 16),
      ),
    );
  }

  Widget _buildDebugButton() {
    const bool prototypeTestMode = true;
    if (prototypeTestMode) {
      final appDateProvider = context.watch<AppDateProvider>();

      return Positioned(
        right: 12,
        top: 12,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: appDateProvider.isLoaded
                  ? () => appDateProvider.moveToNextDay()
                  : null,
              style: ElevatedButton.styleFrom(minimumSize: Size(60, 30)),
              child: const Text('翌日'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _resetPrototypeData,
              style: ElevatedButton.styleFrom(minimumSize: Size(60, 30)),
              child: const Text('リセット'),
            ),
          ],
        ),
      );
    }
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class _SlotLayout {
  const _SlotLayout(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}

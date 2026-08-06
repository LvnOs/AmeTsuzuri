import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ame_tsuzuri/features/bookshelf/presentation/bookshelf_page.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/letters/presentation/letter_page.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  String _selectedArea = '部屋の中をタップしてみてください';

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
    final repository = LetterRepository();
    final readLetterProvider = context.read<ReadLetterProvider>();
    final shizukuProvider = context.read<ShizukuProvider>();
    final today = context.read<AppDateProvider>().today;
    final letter = await repository.getByDate(today);

    if (!mounted) {
      return;
    }

    if (letter == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('今日の手紙はまだ届いていません')));

      return;
    }

    final isFirstLetter = readLetterProvider.readLetterIds.isEmpty;

    final isFirstRead = await readLetterProvider.markAsRead(letter.id);

    if (isFirstRead) {
      final reward = isFirstLetter ? 30 : 10;
      await shizukuProvider.addShizuku(reward);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => LetterPage(letter: letter)),
    );
  }

  // 目録ページへの遷移
  void _onTapCatalog() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const CatalogPage()));
  }

  Future<void> _resetPrototypeData() async {
    await context.read<ReadLetterProvider>().reset();
    await context.read<ShizukuProvider>().reset();
    await context.read<CatalogProvider>().reset();

    if (!mounted) {
      return;
    }

    context.read<AppDateProvider>().startPrototypePeriod();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('テストデータをリセットしました')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F3A35),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(aspectRatio: 16 / 9, child: _buildRoom()),
              ),
            ),
            _buildMessageArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoom() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),

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

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
    );
  }

  Widget _buildTapArea({
    required String name,
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color,
    required VoidCallback onTap,
    bool showDebugArea = true,
  }) {
    return Positioned(
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
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF201F1C),
      child: Text(
        _selectedArea,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFE8E1D4), fontSize: 16),
      ),
    );
  }

  Widget _buildDebugButton() {
    const bool prototypeTestMode = true;
    if (prototypeTestMode) {
      return Positioned(
        right: 12,
        top: 12,
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.read<AppDateProvider>().moveToNextDay();
              },
              child: const Text('翌日'),
              style: ElevatedButton.styleFrom(minimumSize: Size(100, 50)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _resetPrototypeData,
              child: const Text('リセット'),
              style: ElevatedButton.styleFrom(minimumSize: Size(100, 50)),
            ),
          ],
        ),
      );
    }
  }
}

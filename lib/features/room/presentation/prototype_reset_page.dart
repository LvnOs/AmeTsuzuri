import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/provider/read_letter_provider.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/repository/letter_repository.dart';
import 'package:ame_tsuzuri/features/room/presentation/room_page.dart';
import 'package:ame_tsuzuri/shared/provider/app_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrototypeResetPage extends StatefulWidget {
  const PrototypeResetPage({
    super.key,
    this.letterRepository,
    this.furnitureRepository,
  });

  final LetterRepository? letterRepository;
  final FurnitureRepository? furnitureRepository;

  @override
  State<PrototypeResetPage> createState() => _PrototypeResetPageState();
}

class _PrototypeResetPageState extends State<PrototypeResetPage> {
  bool _didStart = false;
  bool _isResetting = false;
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStart) {
      return;
    }
    _didStart = true;
    _resetPrototype();
  }

  Future<void> _resetPrototype() async {
    if (_isResetting) {
      return;
    }

    setState(() {
      _isResetting = true;
      _error = null;
    });

    final placedFurnitureProvider = context.read<PlacedFurnitureProvider>();
    final catalogProvider = context.read<CatalogProvider>();
    final readLetterProvider = context.read<ReadLetterProvider>();
    final shizukuProvider = context.read<ShizukuProvider>();
    final appDateProvider = context.read<AppDateProvider>();

    try {
      await Future.wait([
        placedFurnitureProvider.load(),
        catalogProvider.load(),
        readLetterProvider.load(),
        shizukuProvider.load(),
        appDateProvider.load(),
      ]);
      await placedFurnitureProvider.reset();
      await catalogProvider.reset();
      await readLetterProvider.reset();
      await shizukuProvider.reset();
      await appDateProvider.startPrototypePeriod();

      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => RoomPage(
            letterRepository: widget.letterRepository,
            furnitureRepository: widget.furnitureRepository,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = true;
        _isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9E1D2),
        body: Center(
          child: _error == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('最初から準備しています…'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('初期化に失敗しました'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _isResetting ? null : _resetPrototype,
                      child: const Text('もう一度試す'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

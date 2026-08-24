import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../letters/provider/shizuku_provider.dart';
import '../../furniture/model/furniture.dart';
import '../../furniture/model/placement_slot.dart';
import '../../furniture/provider/catalog_provider.dart';
import '../../furniture/repository/furniture_repository.dart';
import '../../furniture/repository/placement_slot_repository.dart';
import '../provider/placed_furniture_provider.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    super.key,
    this.showTutorialGuide = false,
    this.furnitureRepository,
    this.placementSlotRepository,
  });

  final bool showTutorialGuide;
  final FurnitureRepository? furnitureRepository;
  final PlacementSlotRepository? placementSlotRepository;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const String _removeAction = '__remove__';
  static const Color _pageBackgroundColor = Color(0xFFE5DDD0);
  static const Color _paperColor = Color(0xFFFFFAEC);
  static const Color _inkColor = Color(0xFF3F382F);
  static const Color _secondaryInkColor = Color(0xFF71685D);
  static const Color _ruleColor = Color(0x268A8175);

  late final FurnitureRepository _furnitureRepository;
  late final PlacementSlotRepository _placementSlotRepository;

  late final Future<List<Furniture>> _furnituresFuture;

  @override
  void initState() {
    super.initState();

    _furnitureRepository = widget.furnitureRepository ?? FurnitureRepository();
    _placementSlotRepository =
        widget.placementSlotRepository ?? PlacementSlotRepository();
    _furnituresFuture = _furnitureRepository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    final shizukuProvider = context.watch<ShizukuProvider>();
    final catalogProvider = context.watch<CatalogProvider>();
    final placedFurnitureProvider = context.watch<PlacedFurnitureProvider>();
    final areProvidersLoaded =
        shizukuProvider.isLoaded &&
        catalogProvider.isLoaded &&
        placedFurnitureProvider.isLoaded;

    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      appBar: AppBar(
        title: const Text('家具目録'),
        backgroundColor: _pageBackgroundColor,
        foregroundColor: _inkColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                key: const ValueKey('catalogPaper'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
                decoration: BoxDecoration(
                  color: _paperColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x263D342B),
                      blurRadius: 24,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '家具目録',
                      key: ValueKey('catalogPaperTitle'),
                      style: TextStyle(
                        color: _inkColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildShizukuBalance(shizukuProvider),
                    if (widget.showTutorialGuide) ...[
                      const SizedBox(height: 12),
                      const Text(
                        '気に入った家具を、ひとつ迎えてみましょう。',
                        style: TextStyle(
                          color: _secondaryInkColor,
                          fontSize: 14,
                          height: 1.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Divider(height: 1, thickness: 0.8, color: _ruleColor),
                    Expanded(
                      child: FutureBuilder<List<Furniture>>(
                        future: _furnituresFuture,
                        builder: (context, snapshot) {
                          if (!areProvidersLoaded ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '家具の読み込みに失敗しました\n'
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _inkColor),
                              ),
                            );
                          }

                          final furnitures = snapshot.data ?? [];
                          final availableFurnitures = furnitures
                              .where((furniture) => furniture.initialAvailable)
                              .toList();
                          if (availableFurnitures.isEmpty) {
                            return const Center(
                              child: Text(
                                '家具はまだありません',
                                style: TextStyle(color: _secondaryInkColor),
                              ),
                            );
                          }

                          return ListView.separated(
                            key: const ValueKey('catalogFurnitureList'),
                            padding: EdgeInsets.zero,
                            itemCount: availableFurnitures.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              thickness: 0.8,
                              color: _ruleColor,
                            ),
                            itemBuilder: (context, index) {
                              final furniture = availableFurnitures[index];
                              final isPurchased = catalogProvider.isPurchased(
                                furniture.id,
                              );
                              final isPurchasing =
                                  catalogProvider.purchasingFurnitureId ==
                                  furniture.id;
                              final isPlaced =
                                  placedFurnitureProvider
                                      .getSlotIdByFurnitureId(furniture.id) !=
                                  null;

                              return _CatalogFurnitureRow(
                                index: index,
                                furniture: furniture,
                                isPurchased: isPurchased,
                                isPlaced: isPlaced,
                                isPurchasing: isPurchasing,
                                onTap:
                                    !isPurchased && catalogProvider.isPurchasing
                                    ? null
                                    : () {
                                        if (isPurchased) {
                                          _showPlacementDialog(
                                            context,
                                            furniture,
                                          );
                                        } else {
                                          _showPurchaseDialog(
                                            context,
                                            furniture,
                                          );
                                        }
                                      },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShizukuBalance(ShizukuProvider shizukuProvider) {
    return Text(
      shizukuProvider.isLoaded
          ? '所持雫 ${shizukuProvider.currentShizuku}滴'
          : '所持雫 --',
      key: const ValueKey('catalogShizukuBalance'),
      style: const TextStyle(
        color: _secondaryInkColor,
        fontSize: 14,
        letterSpacing: 0.3,
      ),
    );
  }

  Future<void> _showPurchaseDialog(
    BuildContext context,
    Furniture furniture,
  ) async {
    final shouldBuy = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(furniture.name),
          content: Text('${furniture.price}滴で迎えますか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('やめる'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('迎える'),
            ),
          ],
        );
      },
    );

    if (shouldBuy != true || !context.mounted) {
      return;
    }

    final catalogProvider = context.read<CatalogProvider>();

    final shizukuProvider = context.read<ShizukuProvider>();

    late final FurniturePurchaseResult result;
    try {
      result = await catalogProvider.buy(
        furniture: furniture,
        shizukuProvider: shizukuProvider,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('家具を迎えられませんでした')),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    final message = switch (result) {
      FurniturePurchaseResult.success => '${furniture.name}を迎えました',
      FurniturePurchaseResult.alreadyPurchased => 'この家具は購入済みです',
      FurniturePurchaseResult.notEnoughShizuku => '雫が足りません',
      FurniturePurchaseResult.purchaseInProgress => '購入処理中です',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (result == FurniturePurchaseResult.success) {
      await _showPlacementDialog(context, furniture, isJustPurchased: true);
    }
  }

  Future<void> _showPlacementDialog(
    BuildContext context,
    Furniture furniture, {
    bool isJustPurchased = false,
  }) async {
    final placedFurnitureProvider = context.read<PlacedFurnitureProvider>();
    final currentSlotId = placedFurnitureProvider.getSlotIdByFurnitureId(
      furniture.id,
    );
    final slotResults = await Future.wait(
      furniture.slotIds.map(_placementSlotRepository.getById),
    );
    final slots = slotResults.whereType<PlacementSlot>().toList();
    final currentSlot = currentSlotId == null
        ? null
        : await _placementSlotRepository.getById(currentSlotId);

    if (!context.mounted) {
      return;
    }

    final selectedAction = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(furniture.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'どこに置きますか？',
                style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isJustPurchased) ...[
                const SizedBox(height: 12),
                const Text('迎えた家具を、部屋に置いてみましょう。'),
              ],
              const SizedBox(height: 8),
              const Text('置く場所を選んでください。'),
              const SizedBox(height: 16),
              Text(
                currentSlot == null
                    ? '現在の配置場所：未配置'
                    : '現在の配置場所：${currentSlot.name}',
              ),
              const SizedBox(height: 12),
              ...slots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: ValueKey('placementOption-${slot.id}'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(slot.id);
                      },
                      icon: Icon(
                        slot.id == currentSlotId
                            ? Icons.check_circle_outline
                            : Icons.chair_outlined,
                        size: 20,
                      ),
                      label: Text(
                        '${slot.name}に置く',
                        textAlign: TextAlign.center,
                        softWrap: true,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          scrollable: true,
          actions: [
            if (currentSlotId != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(_removeAction);
                },
                child: const Text('取り外す'),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('キャンセル'),
            ),
          ],
        );
      },
    );

    if (selectedAction == null || !context.mounted) {
      return;
    }

    if (selectedAction == _removeAction) {
      await placedFurnitureProvider.remove(furniture.id);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${furniture.name}を取り外しました')));
      return;
    }

    final furnitureAtSelectedSlot =
        placedFurnitureProvider.placedFurnitureIds[selectedAction];
    if (furnitureAtSelectedSlot != null &&
        furnitureAtSelectedSlot != furniture.id) {
      final shouldReplace = await _showReplacementConfirmation(context);

      if (shouldReplace != true || !context.mounted) {
        return;
      }
    }

    final catalogProvider = context.read<CatalogProvider>();
    final result = await placedFurnitureProvider.place(
      slotId: selectedAction,
      furnitureId: furniture.id,
      isPurchased: catalogProvider.isPurchased(furniture.id),
      allowedSlotIds: furniture.slotIds,
    );

    if (!context.mounted) {
      return;
    }

    final message = switch (result) {
      PlaceFurnitureResult.success => '${furniture.name}を配置しました',
      PlaceFurnitureResult.notPurchased => '未購入の家具は配置できません',
      PlaceFurnitureResult.invalidSlot => 'この場所には配置できません',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool?> _showReplacementConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: const Text(
            'この場所にはすでに家具が配置されています。\n'
            '置き換えますか？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('置き換える'),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogFurnitureRow extends StatelessWidget {
  const _CatalogFurnitureRow({
    required this.index,
    required this.furniture,
    required this.isPurchased,
    required this.isPlaced,
    required this.isPurchasing,
    required this.onTap,
  });

  final int index;
  final Furniture furniture;
  final bool isPurchased;
  final bool isPlaced;
  final bool isPurchasing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stateText = !isPurchased
        ? '${furniture.price}滴で迎える'
        : isPlaced
        ? '配置を変える'
        : '配置する';

    return InkWell(
      key: ValueKey('catalogFurnitureRow-${furniture.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 42,
              child: Text(
                'No.${(index + 1).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: _CatalogPageState._secondaryInkColor,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            _FurniturePreview(furniture: furniture),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    furniture.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CatalogPageState._inkColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (isPurchased) ...[
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: _CatalogPageState._secondaryInkColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          stateText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _CatalogPageState._secondaryInkColor,
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (isPurchasing)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 1.8),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FurniturePreview extends StatelessWidget {
  const _FurniturePreview({required this.furniture});

  static const double _previewSize = 64;

  final Furniture furniture;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: ValueKey('catalogFurniturePreview-${furniture.id}'),
      dimension: _previewSize,
      child: ColoredBox(
        color: const Color(0xFFF5F0E4),
        child: Image.asset(
          'assets/images/${furniture.imagePath}',
          key: ValueKey('catalogFurnitureImage-${furniture.id}'),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.expand(),
        ),
      ),
    );
  }
}

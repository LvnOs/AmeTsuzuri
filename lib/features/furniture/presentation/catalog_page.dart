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
    this.furnitureRepository,
    this.placementSlotRepository,
  });

  final FurnitureRepository? furnitureRepository;
  final PlacementSlotRepository? placementSlotRepository;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  static const String _removeAction = '__remove__';

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
      appBar: AppBar(title: const Text('家具目録')),
      body: Column(
        children: [
          _buildShizukuBalance(shizukuProvider),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Furniture>>(
              future: _furnituresFuture,
              builder: (context, snapshot) {
                if (!areProvidersLoaded ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '家具の読み込みに失敗しました\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final furnitures = snapshot.data ?? [];
                if (furnitures.isEmpty) {
                  return const Center(child: Text('家具はまだありません'));
                }

                return ListView.builder(
                  itemCount: furnitures.length,
                  itemBuilder: (context, index) {
                    final furniture = furnitures[index];
                    final isPurchased = catalogProvider.isPurchased(
                      furniture.id,
                    );
                    final isPurchasing =
                        catalogProvider.purchasingFurnitureId == furniture.id;
                    final isPlaced =
                        placedFurnitureProvider.getSlotIdByFurnitureId(
                          furniture.id,
                        ) !=
                        null;

                    return ListTile(
                      leading: _FurniturePreview(furniture: furniture),
                      title: _buildFurnitureTitle(furniture, isPurchased),
                      subtitle: Text(
                        !isPurchased
                            ? '${furniture.price}滴で迎える'
                            : isPlaced
                            ? '配置を変える'
                            : '配置する',
                      ),
                      trailing: isPurchasing
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: !isPurchased && catalogProvider.isPurchasing
                          ? null
                          : () {
                              if (isPurchased) {
                                _showPlacementDialog(context, furniture);
                              } else {
                                _showPurchaseDialog(context, furniture);
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
    );
  }

  Widget _buildShizukuBalance(ShizukuProvider shizukuProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.water_drop_outlined, size: 20),
          const SizedBox(width: 8),
          Text(
            shizukuProvider.isLoaded
                ? '所持雫 ${shizukuProvider.currentShizuku}滴'
                : '所持雫 --',
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureTitle(Furniture furniture, bool isPurchased) {
    final name = Text(
      furniture.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (!isPurchased) {
      return name;
    }

    return Row(
      children: [
        const Icon(Icons.check_circle_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: name),
      ],
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

    final result = await catalogProvider.buy(
      furniture: furniture,
      shizukuProvider: shizukuProvider,
    );

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
  }

  Future<void> _showPlacementDialog(
    BuildContext context,
    Furniture furniture,
  ) async {
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
                currentSlot == null
                    ? '現在の配置場所：未配置'
                    : '現在の配置場所：${currentSlot.name}',
              ),
              const SizedBox(height: 16),
              const Text('配置可能な場所'),
              const SizedBox(height: 8),
              ...slots.map(
                (slot) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(slot.name),
                  trailing: slot.id == currentSlotId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    Navigator.of(dialogContext).pop(slot.id);
                  },
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${furniture.name}を取り外しました')),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        color: const Color(0xFFF2EFE8),
        child: Image.asset(
          'assets/images/${furniture.imagePath}',
          key: ValueKey('catalogFurnitureImage-${furniture.id}'),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox.expand(),
        ),
      ),
    );
  }
}

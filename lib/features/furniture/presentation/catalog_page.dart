import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../letters/provider/shizuku_provider.dart';
import '../../furniture/model/furniture.dart';
import '../../furniture/provider/catalog_provider.dart';
import '../../furniture/repository/furniture_repository.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final FurnitureRepository _furnitureRepository = FurnitureRepository();

  late final Future<List<Furniture>> _furnituresFuture;

  @override
  void initState() {
    super.initState();

    _furnituresFuture = _furnitureRepository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    final currentShizuku = context.watch<ShizukuProvider>().currentShizuku;

    final catalogProvider = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('家具目録'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('雫 $currentShizuku')),
          ),
        ],
      ),
      body: FutureBuilder<List<Furniture>>(
        future: _furnituresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
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

              final isPurchased = catalogProvider.isPurchased(furniture.id);

              return ListTile(
                title: Text(furniture.name),
                subtitle: Text(isPurchased ? '購入済み' : '${furniture.price}滴'),
                trailing: isPurchased
                    ? const Icon(Icons.check)
                    : const Icon(Icons.chevron_right),
                enabled: !isPurchased,
                onTap: isPurchased
                    ? null
                    : () => _showPurchaseDialog(context, furniture),
              );
            },
          );
        },
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
          content: Text('${furniture.price}滴で購入しますか？'),
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
              child: const Text('購入'),
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
      FurniturePurchaseResult.success => '${furniture.name}を購入しました',
      FurniturePurchaseResult.alreadyPurchased => 'この家具は購入済みです',
      FurniturePurchaseResult.notEnoughShizuku => '雫が足りません',
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

import 'dart:async';

import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/furniture/model/placement_slot.dart';
import 'package:ame_tsuzuri/features/furniture/presentation/catalog_page.dart';
import 'package:ame_tsuzuri/features/furniture/provider/catalog_provider.dart';
import 'package:ame_tsuzuri/features/furniture/provider/placed_furniture_provider.dart';
import 'package:ame_tsuzuri/features/furniture/repository/furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placed_furniture_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/placement_slot_repository.dart';
import 'package:ame_tsuzuri/features/furniture/repository/purchased_furniture_repository.dart';
import 'package:ame_tsuzuri/features/letters/provider/shizuku_provider.dart';
import 'package:ame_tsuzuri/features/letters/model/shizuku_state.dart';
import 'package:ame_tsuzuri/features/letters/repository/shizuku_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _deskSurfaceLeftSlotId = 'living_room_desk_surface_left';

const _furnitureA = Furniture(
  id: 'furniture_a',
  name: '家具A',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _furnitureB = Furniture(
  id: 'furniture_b',
  name: '家具B',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _furnitureC = Furniture(
  id: 'furniture_c',
  name: '家具C',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _longNameFurniture = Furniture(
  id: 'long_name_furniture',
  name: 'とても長い名前の木製アンティークチェア',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);
const _woodenMug = Furniture(
  id: 'wooden_mug',
  name: '木のマグ',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId],
  imagePath: 'furniture/desk/wooden_mug.png',
  initialAvailable: true,
);
const _inkBottle = Furniture(
  id: 'ink_bottle',
  name: 'インク瓶',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId],
  imagePath: 'furniture/desk/ink_bottle.png',
  initialAvailable: true,
);
const _woodenFoxFigure = Furniture(
  id: 'wooden_fox_figure',
  name: '木彫りのキツネ',
  price: 30,
  size: 'small',
  slotIds: [_deskSurfaceLeftSlotId],
  imagePath: 'furniture/desk/wooden_fox_figure.png',
  initialAvailable: true,
);
const _missingImageFurniture = Furniture(
  id: 'missing_image',
  name: '画像のない家具',
  price: 30,
  size: 'small',
  slotIds: ['test_slot'],
  imagePath: 'furniture/desk/missing.png',
  initialAvailable: true,
);
const _hiddenFurniture = Furniture(
  id: 'hidden_furniture',
  name: '非公開家具',
  price: 30,
  size: 'small',
  slotIds: ['legacy_slot'],
  imagePath: 'unused.png',
  initialAvailable: false,
);
const _multiSlotFurniture = Furniture(
  id: 'multi_slot_furniture',
  name: '複数配置家具',
  price: 30,
  size: 'small',
  slotIds: ['slot_a', 'long_slot'],
  imagePath: 'unused.png',
  initialAvailable: true,
);

void main() {
  testWidgets('Providerロード中は進捗表示しロード後に家具一覧へ切り替わる', (tester) async {
    final harness = await _pumpCatalog(tester, loadCatalogProvider: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await harness.catalogProvider.load();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(_catalogFurnitureRows, findsNWidgets(3));
  });

  group('CatalogPageの公開家具フィルタ', () {
    testWidgets('initialAvailableがtrueの家具だけを表示する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _hiddenFurniture],
        purchasedFurnitureIds: const {},
      );

      expect(find.text(_furnitureA.name), findsOneWidget);
      expect(find.text(_hiddenFurniture.name), findsNothing);
      expect(_catalogFurnitureRows, findsOneWidget);
    });

    testWidgets('非公開家具の旧購入・旧配置データがあっても公開家具を操作できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _hiddenFurniture],
        purchasedFurnitureIds: const {'hidden_furniture'},
        placedFurnitureIds: const {'legacy_slot': 'hidden_furniture'},
      );

      expect(find.text(_hiddenFurniture.name), findsNothing);
      expect(find.text(_furnitureA.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_furnitureA.name));
      await tester.pumpAndSettle();
      expect(find.text('30滴で迎えますか？'), findsOneWidget);
    });
  });

  group('CatalogPageの家具目録ビジュアル', () {
    testWidgets('tutorial初回導線では家具一覧の前に短いガイドを表示する', (tester) async {
      await _pumpCatalog(tester, showTutorialGuide: true);

      expect(find.text('気に入った家具を、ひとつ迎えてみましょう。'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('catalogFurnitureList')),
        findsOneWidget,
      );
    });

    testWidgets('通常表示ではtutorialガイドを表示しない', (tester) async {
      await _pumpCatalog(tester);

      expect(find.text('気に入った家具を、ひとつ迎えてみましょう。'), findsNothing);
    });

    testWidgets('背景と紙面と目録ヘッダーを表示する', (tester) async {
      await _pumpCatalog(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      final paper = tester.widget<Container>(
        find.byKey(const ValueKey('catalogPaper')),
      );
      final decoration = paper.decoration! as BoxDecoration;

      expect(scaffold.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.backgroundColor, const Color(0xFFE5DDD0));
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
      expect(decoration.color, const Color(0xFFFFFAEC));
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(decoration.boxShadow, isNotEmpty);
      expect(find.byKey(const ValueKey('catalogPaperTitle')), findsOneWidget);
      expect(find.text('家具目録'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('catalogShizukuBalance')),
        findsOneWidget,
      );
      expect(find.text('所持雫 100滴'), findsOneWidget);
    });

    testWidgets('正式3家具を目録番号と安定した行Keyで表示する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle, _woodenFoxFigure],
        purchasedFurnitureIds: const {},
      );

      for (var index = 0; index < 3; index++) {
        final furniture = [_woodenMug, _inkBottle, _woodenFoxFigure][index];
        expect(
          find.byKey(ValueKey('catalogFurnitureRow-${furniture.id}')),
          findsOneWidget,
        );
        expect(find.text('No.0${index + 1}'), findsOneWidget);
      }
    });

    testWidgets('未購入・購入済み未配置・配置済みを文字で判別できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_furnitureA, _furnitureB, _furnitureC],
        purchasedFurnitureIds: const {'furniture_b', 'furniture_c'},
        placedFurnitureIds: const {'test_slot': 'furniture_c'},
      );

      expect(find.text('30滴で迎える'), findsOneWidget);
      expect(find.text('配置する'), findsOneWidget);
      expect(find.text('配置を変える'), findsOneWidget);
    });

    testWidgets('390x700で紙面と家具行が横overflowしない', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle, _woodenFoxFigure],
        purchasedFurnitureIds: const {'ink_bottle'},
      );

      expect(find.byKey(const ValueKey('catalogPaper')), findsOneWidget);
      expect(_catalogFurnitureRows, findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PC幅でも紙面は640pxを超えない', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(tester);

      expect(
        tester.getSize(find.byKey(const ValueKey('catalogPaper'))).width,
        lessThanOrEqualTo(640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('公開家具が増えても目録内を縦スクロールできる', (tester) async {
      final furnitures = List.generate(
        10,
        (index) => Furniture(
          id: 'scroll_furniture_$index',
          name: '家具$index',
          price: 30,
          size: 'small',
          slotIds: const ['test_slot'],
          imagePath: 'unused.png',
          initialAvailable: true,
        ),
      );
      await _pumpCatalog(
        tester,
        furnitures: furnitures,
        purchasedFurnitureIds: const {},
      );

      final list = find.byKey(const ValueKey('catalogFurnitureList'));
      expect(list, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('家具9'),
        250,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('家具9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogPageの家具画像プレビュー', () {
    for (final furniture in [_woodenMug, _inkBottle, _woodenFoxFigure]) {
      testWidgets('${furniture.id}はFurniture.imagePathの画像を表示する', (
        tester,
      ) async {
        await _pumpCatalog(
          tester,
          furnitures: [furniture],
          purchasedFurnitureIds: const {},
        );

        final preview = tester.widget<SizedBox>(
          find.byKey(ValueKey('catalogFurniturePreview-${furniture.id}')),
        );
        final image = tester.widget<Image>(
          find.byKey(ValueKey('catalogFurnitureImage-${furniture.id}')),
        );
        expect(preview.width, 64);
        expect(preview.height, 64);
        expect(image.fit, BoxFit.contain);
        expect(
          (image.image as AssetImage).assetName,
          'assets/images/${furniture.imagePath}',
        );
      });
    }

    testWidgets('画像欠落でも家具名と購入操作を維持する', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        furnitures: const [_missingImageFurniture],
        purchasedFurnitureIds: const {},
      );
      await tester.pump();

      expect(find.text(_missingImageFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_missingImageFurniture.name));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('画像欠落でも購入済み家具の配置場所を選択できる', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_missingImageFurniture],
        purchasedFurnitureIds: const {'missing_image'},
      );
      await tester.pump();

      expect(find.text(_missingImageFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(_furnitureTile(_missingImageFurniture.name));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('placementOption-test_slot')),
        findsOneWidget,
      );
    });

    testWidgets('プレビュー追加後も所持雫と購入状態を維持する', (tester) async {
      await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'ink_bottle'},
      );

      expect(_textContainingAscii('100'), findsOneWidget);
      expect(_textContainingAscii('30'), findsOneWidget);
      expect(_purchasedCheckInTile(_inkBottle.name), findsOneWidget);
      expect(_purchasedCheckInTile(_woodenMug.name), findsNothing);
    });
  });

  group('正式3家具のMVP操作', () {
    for (final furniture in [_woodenMug, _inkBottle, _woodenFoxFigure]) {
      testWidgets('${furniture.id}を30雫で購入できる', (tester) async {
        await _pumpCatalog(
          tester,
          blockPurchase: false,
          initialShizuku: 30,
          furnitures: [furniture],
          purchasedFurnitureIds: const {},
        );

        await tester.tap(_furnitureTile(furniture.name));
        await tester.pumpAndSettle();
        await tester.tap(find.text('迎える'));
        await tester.pumpAndSettle();

        expect(find.text('${furniture.name}を迎えました'), findsOneWidget);
        expect(find.text('所持雫 0滴'), findsOneWidget);
        expect(_purchasedCheckInTile(furniture.name), findsOneWidget);
      });
    }

    testWidgets('机上Aで正式家具を交換して旧家具の購入済み状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug, _inkBottle],
        purchasedFurnitureIds: const {'wooden_mug', 'ink_bottle'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_inkBottle.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_left'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('置き換える'));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceLeftSlotId: 'ink_bottle',
      });
      expect(harness.catalogProvider.isPurchased('wooden_mug'), isTrue);
      expect(harness.catalogProvider.isPurchased('ink_bottle'), isTrue);
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('机上Aから取り外した購入済み家具を再配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        furnitures: const [_woodenMug],
        purchasedFurnitureIds: const {'wooden_mug'},
        placedFurnitureIds: const {_deskSurfaceLeftSlotId: 'wooden_mug'},
      );

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取り外す'));
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
      expect(_purchasedCheckInTile(_woodenMug.name), findsOneWidget);

      await tester.tap(_furnitureTile(_woodenMug.name));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('placementOption-living_room_desk_surface_left'),
        ),
      );
      await tester.pumpAndSettle();
      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        _deskSurfaceLeftSlotId: 'wooden_mug',
      });
    });
  });

  group('CatalogPageの初見UX表示', () {
    testWidgets('未購入家具に価格と迎える導線を表示する', (tester) async {
      await _pumpCatalog(tester);

      expect(find.text('30滴で迎える'), findsNWidgets(2));
      expect(find.text('所持雫 100滴'), findsOneWidget);
      expect(_purchasedCheckInTile('家具A'), findsNothing);
      expect(_purchasedCheckInTile('家具B'), findsNothing);
      expect(_purchasedCheckInTile('家具C'), findsOneWidget);
    });

    testWidgets('未購入家具から迎える確認へ進める', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();

      expect(find.text('30滴で迎えますか？'), findsOneWidget);
      expect(find.text('迎える'), findsOneWidget);
    });

    testWidgets('迎えた家具は配置する表示へ切り替わる', (tester) async {
      await _pumpCatalog(tester, blockPurchase: false);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('迎える'));
      await tester.pumpAndSettle();

      expect(find.text('家具Aを迎えました'), findsOneWidget);
      expect(find.text('配置する'), findsNWidgets(2));
      expect(find.text('所持雫 70滴'), findsOneWidget);
      expect(_purchasedCheckInTile('家具A'), findsOneWidget);
    });

    testWidgets('購入済み未配置家具から配置ダイアログへ進める', (tester) async {
      await _pumpCatalog(tester);

      await tester.tap(_furnitureTile('家具C'));
      await tester.pumpAndSettle();

      expect(find.text('配置する'), findsOneWidget);
      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('迎えた家具を、部屋に置いてみましょう。'), findsNothing);
      expect(find.text('置く場所を選んでください。'), findsOneWidget);
      expect(find.text('テスト配置場所に置く'), findsOneWidget);
    });

    testWidgets('配置済み家具に配置を変えると表示し配置操作へ進める', (tester) async {
      await _pumpCatalog(
        tester,
        placedFurnitureIds: {'test_slot': 'furniture_c'},
      );

      expect(find.text('配置を変える'), findsOneWidget);
      expect(_purchasedCheckInTile('家具C'), findsOneWidget);
      await tester.tap(_furnitureTile('家具C'));
      await tester.pumpAndSettle();

      expect(find.text('現在の配置場所：テスト配置場所'), findsOneWidget);
      expect(find.text('取り外す'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('placementOption-test_slot')),
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('雫未ロード中は所持雫をダッシュ表示にする', (tester) async {
      await _pumpCatalog(tester, loadShizukuProvider: false);

      expect(find.text('所持雫 --'), findsOneWidget);
    });

    testWidgets('雫不足では家具を迎えずエラー表示を維持する', (tester) async {
      await _pumpCatalog(tester, blockPurchase: false, initialShizuku: 20);

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('迎える'));
      await tester.pumpAndSettle();

      expect(find.text('雫が足りません'), findsOneWidget);
      expect(find.text('30滴で迎える'), findsNWidgets(2));
      expect(find.text('所持雫 20滴'), findsOneWidget);
    });

    testWidgets('320px幅で長い家具名と状態表示がoverflowしない', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpCatalog(
        tester,
        furnitures: const [_longNameFurniture],
        purchasedFurnitureIds: const {'long_name_furniture'},
      );

      expect(find.text('所持雫 100滴'), findsOneWidget);
      expect(find.text('配置する'), findsOneWidget);
      expect(_purchasedCheckInTile(_longNameFurniture.name), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('購入成功後の配置Dialog自動表示', () {
    testWidgets('購入した家具の配置Dialogだけを自動表示する', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('家具A'),
        ),
        findsOneWidget,
      );
      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('置く場所を選んでください。'), findsOneWidget);
      expect(find.text('迎えた家具を、部屋に置いてみましょう。'), findsOneWidget);
    });

    testWidgets('購入確認キャンセルでは購入も配置Dialog表示もしない', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('やめる'));
      await tester.pumpAndSettle();

      expect(harness.catalogProvider.isPurchased('furniture_a'), isFalse);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(CatalogPage), findsOneWidget);
    });

    testWidgets('購入失敗では配置Dialogを表示せず状態を維持する', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        failNextShizukuSave: true,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.text('家具を迎えられませんでした'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(harness.catalogProvider.isPurchased('furniture_a'), isFalse);
      expect(harness.shizukuProvider.currentShizuku, 100);
    });

    testWidgets('雫不足では配置Dialogを表示しない', (tester) async {
      await _pumpCatalog(
        tester,
        blockPurchase: false,
        initialShizuku: 20,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');

      expect(find.text('雫が足りません'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('自動配置をキャンセルしても購入と雫消費を維持しCatalogに残る', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(harness.catalogProvider.isPurchased('furniture_a'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 70);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, isEmpty);
      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('自動配置キャンセル後も同じ家具を再操作して配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      await tester.tap(_furnitureTile('家具A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_a',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    testWidgets('購入成功後の自動Dialogから既存配置処理で配置できる', (tester) async {
      final harness = await _pumpCatalog(
        tester,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, '家具A');
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_a',
      });
      expect(find.byType(CatalogPage), findsNothing);
    });

    for (final showTutorialGuide in [true, false]) {
      testWidgets(
        '${showTutorialGuide ? 'tutorial初回' : '通常'}Catalogでも購入後に自動表示する',
        (tester) async {
          await _pumpCatalog(
            tester,
            showTutorialGuide: showTutorialGuide,
            blockPurchase: false,
            purchasedFurnitureIds: const {},
          );

          await _buyFurniture(tester, '家具A');

          expect(find.text('どこに置きますか？'), findsOneWidget);
          expect(find.byType(AlertDialog), findsOneWidget);
        },
      );
    }

    testWidgets('320px幅でも複数slotと長い名前を縦ボタンで表示できる', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _pumpCatalog(
        tester,
        furnitures: const [_multiSlotFurniture],
        purchasedFurnitureIds: const {'multi_slot_furniture'},
      );

      await tester.tap(_furnitureTile('複数配置家具'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('placementOption-slot_a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('placementOption-long_slot')),
        findsOneWidget,
      );
      expect(find.text('窓辺に置く'), findsOneWidget);
      expect(find.text('とても長い名前の配置場所に置く'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CatalogPageの購入排他制御', () {
    testWidgets('購入中は同じ未購入家具を再操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具A'));
      await tester.pump();

      expect(find.text('30滴で迎えますか？'), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.catalogRepository.saveCallCount, 0);

      await harness.finishPurchase(tester);
    });

    testWidgets('購入中は別の未購入家具を操作できない', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具B'));
      await tester.pump();

      expect(find.text('30滴で迎えますか？'), findsNothing);
      expect(harness.shizukuRepository.saveCallCount, 1);
      expect(harness.catalogRepository.saveCallCount, 0);

      await harness.finishPurchase(tester);
    });

    testWidgets('購入中の家具だけにインジケーターを表示する', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');

      expect(_progressInTile('家具A'), findsOneWidget);
      expect(_progressInTile('家具B'), findsNothing);
      expect(_progressInTile('家具C'), findsNothing);

      await harness.finishPurchase(tester);
    });

    testWidgets('別家具の購入中でも購入済み家具の配置操作ができる', (tester) async {
      final harness = await _pumpCatalog(tester);

      await _startPurchase(tester, '家具A');
      await tester.tap(_furnitureTile('家具C'));
      await tester.pump();
      await tester.pump();

      expect(find.text('どこに置きますか？'), findsOneWidget);
      expect(find.text('テスト配置場所に置く'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      await harness.finishPurchase(tester);
    });
  });
  group('CatalogPage placement result', () {
    testWidgets('successful placement returns true and closes Catalog', (
      tester,
    ) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        purchasedFurnitureIds: const {'furniture_c'},
      );

      await tester.tap(_furnitureTile(_furnitureC.name));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsNothing);
      expect(find.text('catalogResult:true'), findsOneWidget);
      expect(harness.placedFurnitureProvider.placedFurnitureIds, const {
        'test_slot': 'furniture_c',
      });
    });

    testWidgets('placement cancellation leaves Catalog open', (tester) async {
      await _pumpCatalog(
        tester,
        openAsRoute: true,
        purchasedFurnitureIds: const {'furniture_c'},
      );

      await tester.tap(_furnitureTile(_furnitureC.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.text('catalogResult:null'), findsNothing);
    });

    testWidgets('new purchase placement returns directly from Catalog', (
      tester,
    ) async {
      final harness = await _pumpCatalog(
        tester,
        openAsRoute: true,
        blockPurchase: false,
        purchasedFurnitureIds: const {},
      );

      await _buyFurniture(tester, _furnitureA.name);
      await tester.tap(find.byKey(const ValueKey('placementOption-test_slot')));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsNothing);
      expect(find.text('catalogResult:true'), findsOneWidget);
      expect(harness.catalogProvider.isPurchased('furniture_a'), isTrue);
      expect(harness.shizukuProvider.currentShizuku, 70);
    });
  });
}

Finder _progressInTile(String furnitureName) {
  return find.descendant(
    of: _furnitureTile(furnitureName),
    matching: find.byType(CircularProgressIndicator),
  );
}

Finder _textContainingAscii(String value) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && (widget.data?.contains(value) ?? false),
  );
}

Finder _furnitureTile(String furnitureName) {
  return find.ancestor(
    of: find.text(furnitureName),
    matching: _catalogFurnitureRows,
  );
}

final _catalogFurnitureRows = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'catalogFurnitureRow-',
      ),
);

Future<void> _startPurchase(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('迎える'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _buyFurniture(WidgetTester tester, String furnitureName) async {
  await tester.tap(_furnitureTile(furnitureName));
  await tester.pumpAndSettle();
  await tester.tap(find.text('迎える'));
  await tester.pumpAndSettle();
}

Future<_CatalogHarness> _pumpCatalog(
  WidgetTester tester, {
  bool openAsRoute = false,
  bool showTutorialGuide = false,
  bool blockPurchase = true,
  bool failNextShizukuSave = false,
  bool loadShizukuProvider = true,
  bool loadCatalogProvider = true,
  int initialShizuku = 100,
  Map<String, String> placedFurnitureIds = const {},
  Set<String> purchasedFurnitureIds = const {'furniture_c'},
  List<Furniture> furnitures = const [_furnitureA, _furnitureB, _furnitureC],
}) async {
  final shizukuRepository = _BlockingShizukuRepository(
    blockSave: blockPurchase,
    initialShizuku: initialShizuku,
  )..failNextSave = failNextShizukuSave;
  addTearDown(shizukuRepository.completeSave);
  final catalogRepository = _FakePurchasedFurnitureRepository(
    purchasedFurnitureIds,
  );
  final shizukuProvider = ShizukuProvider(shizukuRepository);
  final catalogProvider = CatalogProvider(catalogRepository);
  final placedFurnitureProvider = PlacedFurnitureProvider(
    _FakePlacedFurnitureRepository(placedFurnitureIds),
  );

  await Future.wait([
    if (loadShizukuProvider) shizukuProvider.load(),
    if (loadCatalogProvider) catalogProvider.load(),
    placedFurnitureProvider.load(),
  ]);

  final catalogPage = CatalogPage(
    showTutorialGuide: showTutorialGuide,
    furnitureRepository: _FakeFurnitureRepository(furnitures),
    placementSlotRepository: _FakePlacementSlotRepository(),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: shizukuProvider),
        ChangeNotifierProvider.value(value: catalogProvider),
        ChangeNotifierProvider.value(value: placedFurnitureProvider),
      ],
      child: MaterialApp(
        home: openAsRoute
            ? _CatalogRouteHost(catalogPage: catalogPage)
            : catalogPage,
      ),
    ),
  );
  if (loadShizukuProvider && loadCatalogProvider) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  if (openAsRoute) {
    await tester.tap(find.byKey(const ValueKey('openCatalog')));
    await tester.pumpAndSettle();
  }

  return _CatalogHarness(
    shizukuRepository: shizukuRepository,
    catalogRepository: catalogRepository,
    catalogProvider: catalogProvider,
    shizukuProvider: shizukuProvider,
    placedFurnitureProvider: placedFurnitureProvider,
  );
}

class _CatalogRouteHost extends StatefulWidget {
  const _CatalogRouteHost({required this.catalogPage});

  final CatalogPage catalogPage;

  @override
  State<_CatalogRouteHost> createState() => _CatalogRouteHostState();
}

class _CatalogRouteHostState extends State<_CatalogRouteHost> {
  bool? _catalogResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('catalogResult:$_catalogResult'),
          FilledButton(
            key: const ValueKey('openCatalog'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => widget.catalogPage),
              );
              if (mounted) {
                setState(() => _catalogResult = result);
              }
            },
            child: const Text('open'),
          ),
        ],
      ),
    );
  }
}

class _CatalogHarness {
  const _CatalogHarness({
    required this.shizukuRepository,
    required this.catalogRepository,
    required this.catalogProvider,
    required this.shizukuProvider,
    required this.placedFurnitureProvider,
  });

  final _BlockingShizukuRepository shizukuRepository;
  final _FakePurchasedFurnitureRepository catalogRepository;
  final CatalogProvider catalogProvider;
  final ShizukuProvider shizukuProvider;
  final PlacedFurnitureProvider placedFurnitureProvider;

  Future<void> finishPurchase(WidgetTester tester) async {
    shizukuRepository.completeSave();
    await tester.pumpAndSettle();
  }
}

class _FakeFurnitureRepository extends FurnitureRepository {
  _FakeFurnitureRepository(this.furnitures);

  final List<Furniture> furnitures;

  @override
  Future<List<Furniture>> getAll() async => furnitures;
}

class _FakePlacementSlotRepository extends PlacementSlotRepository {
  @override
  Future<PlacementSlot?> getById(String slotId) async => PlacementSlot(
    id: slotId,
    name: switch (slotId) {
      _deskSurfaceLeftSlotId => '机上A',
      'slot_a' => '窓辺',
      'long_slot' => 'とても長い名前の配置場所',
      _ => 'テスト配置場所',
    },
    type: 'surface',
    maxItems: 1,
  );
}

class _FakePurchasedFurnitureRepository extends PurchasedFurnitureRepository {
  _FakePurchasedFurnitureRepository(this.purchasedFurnitureIds);

  final Set<String> purchasedFurnitureIds;
  int saveCallCount = 0;

  @override
  Future<Set<String>> loadPurchasedFurnitureIds() async =>
      Set.of(purchasedFurnitureIds);

  @override
  Future<void> savePurchasedFurnitureIds(Set<String> furnitureIds) async {
    saveCallCount++;
  }
}

class _BlockingShizukuRepository extends ShizukuRepository {
  _BlockingShizukuRepository({
    required this.blockSave,
    required this.initialShizuku,
  });

  final bool blockSave;
  final int initialShizuku;
  final Completer<void> _saveCompleter = Completer<void>();
  int saveCallCount = 0;
  bool failNextSave = false;

  @override
  Future<ShizukuState> loadState() async =>
      ShizukuState(currentShizuku: initialShizuku, rewardedLetterIds: {});

  @override
  Future<void> saveState(ShizukuState state) {
    saveCallCount++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('save failed');
    }
    return blockSave ? _saveCompleter.future : Future.value();
  }

  void completeSave() {
    if (!_saveCompleter.isCompleted) {
      _saveCompleter.complete();
    }
  }
}

class _FakePlacedFurnitureRepository extends PlacedFurnitureRepository {
  _FakePlacedFurnitureRepository(this.placedFurnitureIds);

  final Map<String, String> placedFurnitureIds;

  @override
  Future<Map<String, String>> loadPlacedFurnitureIds() async =>
      placedFurnitureIds;

  @override
  Future<void> savePlacedFurnitureIds(
    Map<String, String> placedFurnitureIds,
  ) async {}
}

Finder _purchasedCheckInTile(String furnitureName) {
  return find.descendant(
    of: _furnitureTile(furnitureName),
    matching: find.byIcon(Icons.check_circle_outline),
  );
}

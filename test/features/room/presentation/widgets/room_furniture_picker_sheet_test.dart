import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:ame_tsuzuri/features/room/presentation/widgets/room_furniture_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slot名・候補・現在配置中を表示して選択IDを返す', (tester) async {
    String? selectedFurnitureId;
    await _pumpPickerLauncher(
      tester,
      onSelected: (value) {
        if (value case RoomFurnitureSelected(:final furnitureId)) {
          selectedFurnitureId = furnitureId;
        }
      },
      candidates: const [_whiteCurtains, _beigeCurtains, _greenCurtains],
      currentFurnitureId: _whiteCurtains.id,
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.text('カーテン'), findsOneWidget);
    expect(find.text(_whiteCurtains.name), findsOneWidget);
    expect(find.text(_beigeCurtains.name), findsOneWidget);
    expect(find.text(_greenCurtains.name), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('roomFurniturePickerCandidate-white_linen_curtains'),
        ),
        matching: find.text('使用中'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('roomFurniturePickerCandidate-beige_curtains'),
        ),
        matching: find.text('使用中'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('roomFurniturePickerCandidate-beige_curtains')),
    );
    await tester.pumpAndSettle();

    expect(selectedFurnitureId, _beigeCurtains.id);
    expect(
      find.byKey(const ValueKey('roomFurniturePickerSheet')),
      findsNothing,
    );
  });

  testWidgets('空候補でも例外にならず0件表示する', (tester) async {
    await _pumpPickerLauncher(tester, candidates: const []);

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('roomFurniturePickerEmpty')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('配置中のときだけ「取り外す」を表示しremove結果を返す', (tester) async {
    RoomFurniturePickerResult? selectedResult;
    await _pumpPickerLauncher(
      tester,
      candidates: const [_whiteCurtains],
      currentFurnitureId: _whiteCurtains.id,
      recoveryActionLabel: '取り外す',
      onSelected: (value) => selectedResult = value,
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    expect(find.text('取り外す'), findsOneWidget);

    await tester.tap(find.text('取り外す'));
    await tester.pumpAndSettle();
    expect(selectedResult, isA<RoomFurnitureRemovalRequested>());
  });

  testWidgets('初期画像があるslotは「元に戻す」を表示する', (tester) async {
    await _pumpPickerLauncher(
      tester,
      candidates: const [_whiteCurtains],
      currentFurnitureId: _whiteCurtains.id,
      recoveryActionLabel: '元に戻す',
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.text('元に戻す'), findsOneWidget);
    expect(find.text('取り外す'), findsNothing);
  });

  testWidgets('配置Mapが空なら復帰操作を表示しない', (tester) async {
    await _pumpPickerLauncher(tester, candidates: const [_whiteCurtains]);

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('roomFurniturePickerRecoveryAction')),
      findsNothing,
    );
  });

  testWidgets('320pxと390pxで多数候補をスクロールできoverflowしない', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final candidates = List.generate(
      12,
      (index) => Furniture(
        id: 'curtain_$index',
        name: '雨の日のカーテン ${index + 1}',
        price: 70,
        size: 'large',
        slotIds: const ['living_room_window_curtain'],
        imagePath: 'furniture/curtain/white_linen_curtains.png',
        initialAvailable: true,
      ),
    );

    for (final size in const [Size(320, 700), Size(390, 700)]) {
      tester.view.physicalSize = size;
      await _pumpPickerLauncher(
        tester,
        candidates: candidates,
        currentFurnitureId: candidates.first.id,
        recoveryActionLabel: '元に戻す',
      );
      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text(candidates.first.name), findsOneWidget);
      final list = find.byKey(const ValueKey('roomFurniturePickerList'));
      await tester.drag(list, const Offset(0, -500));
      await tester.pump();
      await tester.drag(list, const Offset(0, -500));
      await tester.pump();
      expect(find.text(candidates.last.name), findsOneWidget);
      expect(find.text('元に戻す'), findsOneWidget);
      expect(tester.takeException(), isNull);

      Navigator.of(tester.element(find.byType(RoomFurniturePickerSheet))).pop();
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

Future<void> _pumpPickerLauncher(
  WidgetTester tester, {
  required List<Furniture> candidates,
  String? currentFurnitureId,
  String? recoveryActionLabel,
  ValueChanged<RoomFurniturePickerResult?>? onSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final selected =
                    await showModalBottomSheet<RoomFurniturePickerResult>(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => RoomFurniturePickerSheet(
                        slotName: 'カーテン',
                        furnitureCandidates: candidates,
                        currentFurnitureId: currentFurnitureId,
                        recoveryActionLabel: recoveryActionLabel,
                      ),
                    );
                onSelected?.call(selected);
              },
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    ),
  );
}

const _whiteCurtains = Furniture(
  id: 'white_linen_curtains',
  name: '白いリネンのカーテン',
  price: 70,
  size: 'large',
  slotIds: ['living_room_window_curtain'],
  imagePath: 'furniture/curtain/white_linen_curtains.png',
  initialAvailable: true,
);

const _beigeCurtains = Furniture(
  id: 'beige_curtains',
  name: 'ベージュのカーテン',
  price: 70,
  size: 'large',
  slotIds: ['living_room_window_curtain'],
  imagePath: 'furniture/curtain/beige_curtains.png',
  initialAvailable: true,
);

const _greenCurtains = Furniture(
  id: 'deep_green_curtains',
  name: '深緑のカーテン',
  price: 70,
  size: 'large',
  slotIds: ['living_room_window_curtain'],
  imagePath: 'furniture/curtain/deep_green_curtains.png',
  initialAvailable: true,
);

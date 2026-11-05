import 'dart:ui' show Tristate;

import 'package:ame_tsuzuri/features/room/presentation/widgets/room_rearrange_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoomRearrangeOverlay', () {
    testWidgets('通常時は固定サイズの開始タブを表示してcallbackを返す', (tester) async {
      var toggleCount = 0;
      await _pumpOverlay(tester, onToggleRearrangeMode: () => toggleCount += 1);

      expect(find.text('模様替え'), findsOneWidget);
      expect(find.bySemanticsLabel('模様替えを開始'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('rearrangeModeTag'))),
        const Size(84, 46),
      );
      expect(
        find.byKey(const ValueKey('rearrangeInteractionBlocker')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('rearrangeSlotLayer')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('rearrangeModeButton')));
      expect(toggleCount, 1);
    });

    testWidgets('mode中は2行の終了タブ・blocker・slot layerを表示する', (tester) async {
      var toggleCount = 0;
      await _pumpOverlay(
        tester,
        isRearrangeMode: true,
        visibleSlotIds: const ['living_room_chair'],
        onToggleRearrangeMode: () => toggleCount += 1,
      );

      expect(find.text('模様替え中'), findsOneWidget);
      expect(find.text('おわる'), findsOneWidget);
      expect(find.bySemanticsLabel('模様替えを終了'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('rearrangeInteractionBlocker')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('rearrangeSlotLayer')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rearrangeModeButton')));
      expect(toggleCount, 1);
    });

    testWidgets('saving中は開始・終了callbackを無効にする', (tester) async {
      var toggleCount = 0;
      await _pumpOverlay(
        tester,
        isRearrangeMode: true,
        isSaving: true,
        onToggleRearrangeMode: () => toggleCount += 1,
      );

      final button = tester.widget<TextButton>(
        find.byKey(const ValueKey('rearrangeModeButton')),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('rearrangeModeButton')));
      expect(toggleCount, 0);
    });

    testWidgets('入口非表示時はタブを描画しない', (tester) async {
      await _pumpOverlay(tester, showRearrangeButton: false);

      expect(find.byKey(const ValueKey('rearrangeModeTag')), findsNothing);
      expect(find.byKey(const ValueKey('rearrangeModeButton')), findsNothing);
    });

    testWidgets('8slotのgeometry・tap area・Semantics・callbackを維持する', (
      tester,
    ) async {
      const overlaySize = Size(390, 700);
      final tappedSlotIds = <String>[];
      await _pumpOverlay(
        tester,
        size: overlaySize,
        isRearrangeMode: true,
        visibleSlotIds: roomRearrangeSlotIds,
        onSelectSlot: tappedSlotIds.add,
      );

      for (final geometry in _expectedGeometries) {
        final tapArea = find.byKey(
          ValueKey('rearrangeSlotTapArea-${geometry.slotId}'),
        );
        final marker = find.byKey(
          ValueKey('rearrangeSlotMarker-${geometry.slotId}'),
        );
        expect(tapArea, findsOneWidget);
        expect(marker, findsOneWidget);
        expect(find.bySemanticsLabel('${geometry.label}を選ぶ'), findsOneWidget);
        expect(tester.getSize(marker), const Size.square(28));

        final expectedSize = Size(
          overlaySize.width * geometry.widthFactor,
          overlaySize.height * geometry.heightFactor,
        );
        expect(
          tester.getSize(tapArea).width,
          closeTo(expectedSize.width, 0.01),
        );
        expect(
          tester.getSize(tapArea).height,
          closeTo(expectedSize.height, 0.01),
        );
        expect(tester.getSize(tapArea).width, greaterThan(28));
        expect(tester.getSize(tapArea).height, greaterThan(28));

        final expectedCenter = Offset(
          (overlaySize.width - expectedSize.width) /
                  2 *
                  (geometry.alignment.x + 1) +
              expectedSize.width / 2,
          (overlaySize.height - expectedSize.height) /
                  2 *
                  (geometry.alignment.y + 1) +
              expectedSize.height / 2,
        );
        expect(tester.getCenter(tapArea).dx, closeTo(expectedCenter.dx, 0.01));
        expect(tester.getCenter(tapArea).dy, closeTo(expectedCenter.dy, 0.01));

        await tester.tap(tapArea);
        expect(tappedSlotIds.last, geometry.slotId);
      }
    });

    testWidgets('selected markerは34pxと中央点を表示する', (tester) async {
      const slotId = 'living_room_window_curtain';
      await _pumpOverlay(
        tester,
        isRearrangeMode: true,
        visibleSlotIds: const [slotId],
        selectedSlotId: slotId,
      );

      expect(
        tester.getSize(
          find.byKey(const ValueKey('rearrangeSlotMarker-$slotId')),
        ),
        const Size.square(34),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('rearrangeSelectedSlotIndicator')),
        ),
        const Size.square(6),
      );
      final semantics = tester.getSemantics(find.bySemanticsLabel('カーテンを選ぶ'));
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('keyboardのTabとEnterでタブcallbackを返す', (tester) async {
      var toggleCount = 0;
      await _pumpOverlay(tester, onToggleRearrangeMode: () => toggleCount += 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(toggleCount, 1);
    });

    for (final size in const [
      Size(320, 568),
      Size(390, 700),
      Size(1280, 800),
    ]) {
      testWidgets('${size.width.toInt()}px幅でoverflowせず全要素が範囲内に収まる', (
        tester,
      ) async {
        await _pumpOverlay(
          tester,
          size: size,
          isRearrangeMode: true,
          visibleSlotIds: roomRearrangeSlotIds,
        );

        expect(tester.takeException(), isNull);
        final overlayRect = tester.getRect(
          find.byKey(const ValueKey('testOverlayBounds')),
        );
        for (final slotId in roomRearrangeSlotIds) {
          final tapRect = tester.getRect(
            find.byKey(ValueKey('rearrangeSlotTapArea-$slotId')),
          );
          expect(overlayRect.contains(tapRect.topLeft), isTrue);
          expect(overlayRect.contains(tapRect.bottomRight), isTrue);
        }
      });
    }
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  Size size = const Size(390, 700),
  bool isRearrangeMode = false,
  bool isSaving = false,
  bool showRearrangeButton = true,
  Iterable<String> visibleSlotIds = const <String>[],
  String? selectedSlotId,
  VoidCallback? onToggleRearrangeMode,
  ValueChanged<String>? onSelectSlot,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: const ValueKey('testOverlayBounds'),
            width: size.width,
            height: size.height,
            child: RoomRearrangeOverlay(
              isRearrangeMode: isRearrangeMode,
              isSaving: isSaving,
              showRearrangeButton: showRearrangeButton,
              visibleSlotIds: visibleSlotIds,
              selectedSlotId: selectedSlotId,
              onToggleRearrangeMode: onToggleRearrangeMode ?? () {},
              onSelectSlot: onSelectSlot ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

class _ExpectedGeometry {
  const _ExpectedGeometry(
    this.slotId,
    this.label,
    this.alignment,
    this.widthFactor,
    this.heightFactor,
  );

  final String slotId;
  final String label;
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
}

const _expectedGeometries = [
  _ExpectedGeometry(
    'living_room_desk_surface_left',
    '机の左',
    Alignment(-0.64, 0.10),
    0.24,
    0.12,
  ),
  _ExpectedGeometry(
    'living_room_desk_surface_right',
    '机の右',
    Alignment(0.67, 0.10),
    0.24,
    0.12,
  ),
  _ExpectedGeometry(
    'living_room_window_shelf_decor',
    '窓棚',
    Alignment(-0.62, -0.24),
    0.24,
    0.13,
  ),
  _ExpectedGeometry(
    'living_room_window_hanging_decor',
    '吊り飾り',
    Alignment(0.60, -0.88),
    0.20,
    0.20,
  ),
  _ExpectedGeometry(
    'living_room_window_vase',
    '一輪挿し',
    Alignment(0.37, -0.25),
    0.18,
    0.18,
  ),
  _ExpectedGeometry(
    'living_room_window_curtain',
    'カーテン',
    Alignment(-0.88, -0.76),
    0.20,
    0.23,
  ),
  _ExpectedGeometry(
    'living_room_floor_rug',
    'ラグ',
    Alignment(0.10, 0.96),
    0.30,
    0.11,
  ),
  _ExpectedGeometry('living_room_chair', '椅子', Alignment(0, 0.64), 0.34, 0.22),
];

import 'package:flutter/material.dart';

const roomRearrangeSlotIds = [
  'living_room_desk_surface_left',
  'living_room_desk_surface_right',
  'living_room_window_shelf_decor',
  'living_room_window_hanging_decor',
  'living_room_window_vase',
  'living_room_window_curtain',
  'living_room_floor_rug',
  'living_room_chair',
];

String roomRearrangeSlotLabel(String slotId) => _slotGeometry(slotId).label;

class RoomRearrangeOverlay extends StatelessWidget {
  const RoomRearrangeOverlay({
    super.key,
    required this.isRearrangeMode,
    required this.isSaving,
    required this.showRearrangeButton,
    required this.visibleSlotIds,
    required this.selectedSlotId,
    required this.onToggleRearrangeMode,
    required this.onSelectSlot,
  });

  final bool isRearrangeMode;
  final bool isSaving;
  final bool showRearrangeButton;
  final Iterable<String> visibleSlotIds;
  final String? selectedSlotId;
  final VoidCallback onToggleRearrangeMode;
  final ValueChanged<String> onSelectSlot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isRearrangeMode)
          const Positioned.fill(
            child: AbsorbPointer(
              key: ValueKey('rearrangeInteractionBlocker'),
              child: ColoredBox(color: Colors.transparent),
            ),
          ),
        if (isRearrangeMode && showRearrangeButton)
          Stack(
            key: const ValueKey('rearrangeSlotLayer'),
            fit: StackFit.expand,
            children: [
              for (final slotId in visibleSlotIds)
                _RearrangeSlotTarget(
                  slotId: slotId,
                  geometry: _slotGeometry(slotId),
                  isSelected: selectedSlotId == slotId,
                  onTap: () => onSelectSlot(slotId),
                ),
            ],
          ),
        if (showRearrangeButton)
          Positioned(
            right: 0,
            bottom: 14,
            child: _RearrangeModeTag(
              isRearrangeMode: isRearrangeMode,
              isSaving: isSaving,
              onPressed: onToggleRearrangeMode,
            ),
          ),
      ],
    );
  }
}

class _RearrangeModeTag extends StatelessWidget {
  const _RearrangeModeTag({
    required this.isRearrangeMode,
    required this.isSaving,
    required this.onPressed,
  });

  static const _paperColor = Color(0xE8FFFAEE);
  static const _activePaperColor = Color(0xF5FFFAEE);
  static const _inkColor = Color(0xFF463D33);
  static const _mutedSageColor = Color(0xFF596C51);
  static const _borderColor = Color(0x73766B5E);
  static const _activeBorderColor = Color(0xB36F604E);
  static const _shadowColor = Color(0x1F3D342B);
  static const _tabBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(6),
    bottomLeft: Radius.circular(6),
    topRight: Radius.circular(1),
    bottomRight: Radius.circular(1),
  );

  final bool isRearrangeMode;
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = !isSaving;
    return Semantics(
      key: const ValueKey('rearrangeModeSemantics'),
      label: isRearrangeMode ? '模様替えを終了' : '模様替えを開始',
      enabled: enabled,
      child: DecoratedBox(
        key: const ValueKey('rearrangeModeTag'),
        decoration: BoxDecoration(
          color: isRearrangeMode ? _activePaperColor : _paperColor,
          border: Border.all(
            color: isRearrangeMode ? _activeBorderColor : _borderColor,
            width: isRearrangeMode ? 1.2 : 1,
          ),
          borderRadius: _tabBorderRadius,
          boxShadow: const [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 3,
              offset: Offset(-1, 1),
            ),
          ],
        ),
        child: SizedBox(
          width: 84,
          height: 46,
          child: TextButton(
            key: const ValueKey('rearrangeModeButton'),
            onPressed: enabled ? onPressed : null,
            style: TextButton.styleFrom(
              foregroundColor: _inkColor,
              disabledForegroundColor: const Color(0x80463D33),
              backgroundColor: Colors.transparent,
              overlayColor: const Color(0x24596C51),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: _tabBorderRadius),
              visualDensity: VisualDensity.compact,
            ),
            child: ExcludeSemantics(
              child: isRearrangeMode
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '模様替え中',
                          key: ValueKey('rearrangeModeStatusText'),
                          style: TextStyle(
                            color: _mutedSageColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'おわる',
                          key: ValueKey('rearrangeModeActionText'),
                          style: TextStyle(
                            color: _inkColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '模様替え',
                      key: ValueKey('rearrangeModeActionText'),
                      style: TextStyle(
                        color: _inkColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RearrangeSlotTarget extends StatelessWidget {
  const _RearrangeSlotTarget({
    required this.slotId,
    required this.geometry,
    required this.isSelected,
    required this.onTap,
  });

  final String slotId;
  final _RearrangeSlotGeometry geometry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: geometry.alignment,
      child: FractionallySizedBox(
        widthFactor: geometry.widthFactor,
        heightFactor: geometry.heightFactor,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: '${geometry.label}を選ぶ',
          child: GestureDetector(
            key: ValueKey('rearrangeSlotTapArea-$slotId'),
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Center(
              child: SizedBox.square(
                key: ValueKey('rearrangeSlotMarker-$slotId'),
                dimension: isSelected ? 34 : 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xEDFFF8E8)
                        : const Color(0xDFFFF8E8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0x333D342B)
                            : const Color(0x223D342B),
                        blurRadius: isSelected ? 4 : 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSelected ? 2 : 1.75),
                    child: DecoratedBox(
                      key: ValueKey('rearrangeSlotMarkerInner-$slotId'),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xE6EFF0E6)
                            : const Color(0x94FFF8E8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF596C51)
                              : const Color(0xB37E705E),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: DecoratedBox(
                                key: ValueKey('rearrangeSelectedSlotIndicator'),
                                decoration: BoxDecoration(
                                  color: Color(0xFF596C51),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(dimension: 6),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RearrangeSlotGeometry {
  const _RearrangeSlotGeometry({
    required this.label,
    required this.alignment,
    required this.widthFactor,
    required this.heightFactor,
  });

  final String label;
  final Alignment alignment;
  final double widthFactor;
  final double heightFactor;
}

_RearrangeSlotGeometry _slotGeometry(String slotId) {
  return switch (slotId) {
    'living_room_desk_surface_left' => const _RearrangeSlotGeometry(
      label: '机の左',
      alignment: Alignment(-0.64, 0.10),
      widthFactor: 0.24,
      heightFactor: 0.12,
    ),
    'living_room_desk_surface_right' => const _RearrangeSlotGeometry(
      label: '机の右',
      alignment: Alignment(0.67, 0.10),
      widthFactor: 0.24,
      heightFactor: 0.12,
    ),
    'living_room_window_shelf_decor' => const _RearrangeSlotGeometry(
      label: '窓棚',
      alignment: Alignment(-0.62, -0.24),
      widthFactor: 0.24,
      heightFactor: 0.13,
    ),
    'living_room_window_hanging_decor' => const _RearrangeSlotGeometry(
      label: '吊り飾り',
      alignment: Alignment(0.60, -0.88),
      widthFactor: 0.20,
      heightFactor: 0.20,
    ),
    'living_room_window_vase' => const _RearrangeSlotGeometry(
      label: '一輪挿し',
      alignment: Alignment(0.37, -0.25),
      widthFactor: 0.18,
      heightFactor: 0.18,
    ),
    'living_room_window_curtain' => const _RearrangeSlotGeometry(
      label: 'カーテン',
      alignment: Alignment(-0.88, -0.76),
      widthFactor: 0.20,
      heightFactor: 0.23,
    ),
    'living_room_floor_rug' => const _RearrangeSlotGeometry(
      label: 'ラグ',
      alignment: Alignment(0.10, 0.96),
      widthFactor: 0.30,
      heightFactor: 0.11,
    ),
    'living_room_chair' => const _RearrangeSlotGeometry(
      label: '椅子',
      alignment: Alignment(0, 0.64),
      widthFactor: 0.34,
      heightFactor: 0.22,
    ),
    _ => throw ArgumentError.value(slotId, 'slotId'),
  };
}

import 'package:ame_tsuzuri/features/furniture/model/furniture.dart';
import 'package:flutter/material.dart';

sealed class RoomFurniturePickerResult {
  const RoomFurniturePickerResult();
}

final class RoomFurnitureSelected extends RoomFurniturePickerResult {
  const RoomFurnitureSelected(this.furnitureId);

  final String furnitureId;
}

final class RoomFurnitureRemovalRequested extends RoomFurniturePickerResult {
  const RoomFurnitureRemovalRequested();
}

class RoomFurniturePickerSheet extends StatelessWidget {
  const RoomFurniturePickerSheet({
    super.key,
    required this.slotName,
    required this.furnitureCandidates,
    required this.currentFurnitureId,
    this.recoveryActionLabel,
  });

  final String slotName;
  final List<Furniture> furnitureCandidates;
  final String? currentFurnitureId;
  final String? recoveryActionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Container(
          key: const ValueKey('roomFurniturePickerSheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFAEE),
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            border: Border(
              top: BorderSide(color: Color(0x66766B5E), width: 0.8),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x333D342B),
                blurRadius: 16,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 34,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0x66766B5E),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    slotName,
                    key: const ValueKey('roomFurniturePickerSlotName'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF463D33),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0x33766B5E)),
              Flexible(
                child: furnitureCandidates.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 28,
                        ),
                        child: Text(
                          '置ける家具はありません。',
                          key: ValueKey('roomFurniturePickerEmpty'),
                          style: TextStyle(color: Color(0xFF6D6256)),
                        ),
                      )
                    : ListView.separated(
                        key: const ValueKey('roomFurniturePickerList'),
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: furnitureCandidates.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 72,
                          color: Color(0x26766B5E),
                        ),
                        itemBuilder: (context, index) {
                          final furniture = furnitureCandidates[index];
                          return _FurnitureCandidateRow(
                            furniture: furniture,
                            isCurrent: furniture.id == currentFurnitureId,
                            onTap: () => Navigator.of(
                              context,
                            ).pop(RoomFurnitureSelected(furniture.id)),
                          );
                        },
                      ),
              ),
              if (recoveryActionLabel case final label?) ...[
                const Divider(height: 1, color: Color(0x33766B5E)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const ValueKey('roomFurniturePickerRecoveryAction'),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const RoomFurnitureRemovalRequested()),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Color(0xFF665B4F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FurnitureCandidateRow extends StatelessWidget {
  const _FurnitureCandidateRow({
    required this.furniture,
    required this.isCurrent,
    required this.onTap,
  });

  final Furniture furniture;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? const Color(0x597F9275) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: ValueKey('roomFurniturePickerCandidate-${furniture.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 54,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/${furniture.imagePath}',
                      key: ValueKey('roomFurniturePickerImage-${furniture.id}'),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.chair_outlined,
                        color: Color(0x99766B5E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    furniture.name,
                    key: ValueKey('roomFurniturePickerName-${furniture.id}'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF463D33),
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  const Row(
                    key: ValueKey('roomFurniturePickerCurrent'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 17, color: Color(0xFF596C51)),
                      SizedBox(width: 3),
                      Text(
                        '使用中',
                        style: TextStyle(
                          color: Color(0xFF596C51),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

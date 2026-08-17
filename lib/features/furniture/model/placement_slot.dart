class PlacementSlot {
  const PlacementSlot({
    required this.id,
    required this.name,
    required this.type,
    required this.maxItems,
  });

  final String id;
  final String name;
  final String type;
  final int maxItems;
}

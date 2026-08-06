class Furniture {
  const Furniture({
    required this.id,
    required this.name,
    required this.price,
    required this.placementSlotId,
  });

  final String id;
  final String name;
  final int price;
  final String placementSlotId;
}

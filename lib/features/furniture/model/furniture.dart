class Furniture {
  const Furniture({
    required this.id,
    required this.name,
    required this.price,
    required this.size,
    required this.slotIds,
    required this.imagePath,
    required this.initialAvailable,
  });

  final String id;
  final String name;
  final int price;
  final String size;
  final List<String> slotIds;
  final String imagePath;
  final bool initialAvailable;
}

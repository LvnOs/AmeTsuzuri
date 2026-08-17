import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../model/furniture.dart';

class FurnitureRepository {
  Future<List<Furniture>> getAll() async {
    final yamlString = await rootBundle.loadString(
      'assets/data/furniture.yaml',
    );

    final yaml = loadYaml(yamlString);
    final furnitureItems = yaml['furniture'];

    final List<Furniture> furnitures = [];

    for (final item in furnitureItems) {
      furnitures.add(
        Furniture(
          id: item['id'] as String,
          name: item['name'] as String,
          price: item['price'] as int,
          size: item['size'] as String,
          slotIds: List<String>.from(item['slots'] as Iterable),
          imagePath: item['image'] as String,
          initialAvailable: item['initial_available'] as bool,
        ),
      );
    }

    return furnitures;
  }

  Future<Furniture?> getById(String id) async {
    final furnitures = await getAll();

    for (final furniture in furnitures) {
      if (furniture.id == id) {
        return furniture;
      }
    }

    return null;
  }
}

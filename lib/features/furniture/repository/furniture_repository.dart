import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../model/furniture.dart';

class FurnitureRepository {
  Future<List<Furniture>> getAll() async {
    final yamlString = await rootBundle.loadString(
      'assets/data/test_furnitures.yaml',
    );

    final yaml = loadYaml(yamlString);
    final furnitureItems = yaml['furnitures'];

    final List<Furniture> furnitures = [];

    for (final item in furnitureItems) {
      furnitures.add(
        Furniture(
          id: item['id'] as String,
          name: item['name'] as String,
          price: item['price'] as int,
        ),
      );
    }

    return furnitures;
  }
}

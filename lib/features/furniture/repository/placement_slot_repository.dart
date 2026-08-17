import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../model/placement_slot.dart';

class PlacementSlotRepository {
  Future<List<PlacementSlot>> getByRoomId(String roomId) async {
    final rooms = await _loadRooms();

    for (final room in rooms) {
      if (room['id'] == roomId) {
        final slots = room['slots'] as Iterable<dynamic>;

        return slots.map(_toPlacementSlot).toList();
      }
    }

    return [];
  }

  Future<PlacementSlot?> getById(String slotId) async {
    final rooms = await _loadRooms();

    for (final room in rooms) {
      final slots = room['slots'] as Iterable<dynamic>;

      for (final slot in slots) {
        if (slot['id'] == slotId) {
          return _toPlacementSlot(slot);
        }
      }
    }

    return null;
  }

  Future<Iterable<dynamic>> _loadRooms() async {
    final yamlString = await rootBundle.loadString(
      'assets/data/placement_slots.yaml',
    );
    final yaml = loadYaml(yamlString);

    return yaml['rooms'] as Iterable<dynamic>;
  }

  PlacementSlot _toPlacementSlot(dynamic item) {
    return PlacementSlot(
      id: item['id'] as String,
      name: item['name'] as String,
      type: item['type'] as String,
      maxItems: item['max_items'] as int,
    );
  }
}

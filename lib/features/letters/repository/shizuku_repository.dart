import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/shizuku_state.dart';

class ShizukuRepository {
  static const String _stateKey = 'shizukuState';
  static const String _legacyShizukuKey = 'currentShizuku';
  static const String _readLetterIdsKey = 'readLetterIds';
  static const int _currentVersion = 1;

  Future<ShizukuState> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedState = prefs.get(_stateKey);

    if (savedState is String) {
      final state = _decodeState(savedState);
      if (state != null) {
        return state;
      }
    }

    final migratedState = _loadLegacyState(prefs);
    await saveState(migratedState);
    return migratedState;
  }

  Future<void> saveState(ShizukuState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'version': _currentVersion,
      'currentShizuku': state.currentShizuku,
      'rewardedLetterIds': state.rewardedLetterIds.toList(),
    });

    final didSave = await prefs.setString(_stateKey, json);
    if (!didSave) {
      throw StateError('Failed to save shizuku state.');
    }
  }

  Future<void> resetState() async {
    await saveState(
      const ShizukuState(currentShizuku: 0, rewardedLetterIds: {}),
    );

    final prefs = await SharedPreferences.getInstance();
    final didRemoveLegacyState = await prefs.remove(_legacyShizukuKey);
    if (!didRemoveLegacyState && prefs.containsKey(_legacyShizukuKey)) {
      throw StateError('Failed to remove legacy shizuku state.');
    }
  }

  Future<int> loadCurrentShizuku() async {
    final state = await loadState();
    return state.currentShizuku;
  }

  Future<void> saveCurrentShizuku(int shizuku) async {
    final currentState = await loadState();
    await saveState(
      ShizukuState(
        currentShizuku: shizuku,
        rewardedLetterIds: currentState.rewardedLetterIds,
      ),
    );
  }

  Future<void> clear() async {
    await resetState();
  }

  ShizukuState _loadLegacyState(SharedPreferences prefs) {
    final legacyShizuku = prefs.get(_legacyShizukuKey);
    final legacyReadLetterIds = prefs.get(_readLetterIdsKey);

    return ShizukuState(
      currentShizuku: legacyShizuku is int && legacyShizuku >= 0
          ? legacyShizuku
          : 0,
      rewardedLetterIds: legacyReadLetterIds is List
          ? legacyReadLetterIds.whereType<String>().toSet()
          : {},
    );
  }

  ShizukuState? _decodeState(String savedState) {
    try {
      final decoded = jsonDecode(savedState);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final savedShizuku = decoded['currentShizuku'];
      final savedRewardedLetterIds = decoded['rewardedLetterIds'];

      return ShizukuState(
        currentShizuku: savedShizuku is int && savedShizuku >= 0
            ? savedShizuku
            : 0,
        rewardedLetterIds: savedRewardedLetterIds is List
            ? savedRewardedLetterIds.whereType<String>().toSet()
            : {},
      );
    } on FormatException {
      return null;
    }
  }
}

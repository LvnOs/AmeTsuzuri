import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/read_letter_state.dart';

typedef SetStringOverride = Future<bool> Function(String key, String value);

class ReadLetterRepository {
  ReadLetterRepository({this.setStringOverride});

  static const String _stateKey = 'readLetterState';
  static const String _legacyIdsKey = 'readLetterIds';
  static const int _currentVersion = 2;

  final SetStringOverride? setStringOverride;

  Future<ReadLetterState> loadState() async {
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

  Future<void> saveState(ReadLetterState state) async {
    final json = jsonEncode({
      'version': _currentVersion,
      'receivedLetters': state.receivedLetters.map(
        (letterId, receivedDate) => MapEntry(
          letterId,
          receivedDate == null ? null : _formatDate(receivedDate),
        ),
      ),
      'deliveredLetters': state.deliveredLetters,
    });

    final didSave = setStringOverride != null
        ? await setStringOverride!(_stateKey, json)
        : await (await SharedPreferences.getInstance()).setString(
            _stateKey,
            json,
          );
    if (!didSave) {
      throw StateError('Failed to save read letter state.');
    }
  }

  Future<void> resetState() async {
    await saveState(
      ReadLetterState(receivedLetters: {}, deliveredLetters: {}),
    );

    final prefs = await SharedPreferences.getInstance();
    final didRemoveLegacyIds = await prefs.remove(_legacyIdsKey);
    if (!didRemoveLegacyIds && prefs.containsKey(_legacyIdsKey)) {
      throw StateError('Failed to remove legacy read letter ids.');
    }
  }

  Future<Set<String>> loadReadLetterIds() async {
    return (await loadState()).readLetterIds;
  }

  Future<void> saveReadLetterIds(Set<String> ids) async {
    final currentState = await loadState();
    final receivedLetters = <String, DateTime?>{
      for (final id in ids) id: currentState.receivedLetters[id],
    };
    await saveState(
      ReadLetterState(
        receivedLetters: receivedLetters,
        deliveredLetters: currentState.deliveredLetters,
      ),
    );
  }

  Future<void> clear() => resetState();

  ReadLetterState _loadLegacyState(SharedPreferences prefs) {
    final legacyIds = prefs.get(_legacyIdsKey);
    final receivedLetters = <String, DateTime?>{};

    if (legacyIds is List) {
      for (final id in legacyIds.whereType<String>()) {
        receivedLetters[id] = null;
      }
    }

    return ReadLetterState(receivedLetters: receivedLetters);
  }

  ReadLetterState? _decodeState(String savedState) {
    try {
      final decoded = jsonDecode(savedState);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final savedReceivedLetters = decoded['receivedLetters'];
      if (savedReceivedLetters is! Map) {
        return null;
      }

      final receivedLetters = <String, DateTime?>{};
      for (final entry in savedReceivedLetters.entries) {
        final letterId = entry.key;
        final savedDate = entry.value;
        if (letterId is! String) {
          continue;
        }
        if (savedDate == null) {
          receivedLetters[letterId] = null;
          continue;
        }
        if (savedDate is! String) {
          continue;
        }

        final date = _tryParseDate(savedDate);
        if (date != null) {
          receivedLetters[letterId] = date;
        }
      }

      final deliveredLetters = <String, String>{};
      final savedDeliveredLetters = decoded['deliveredLetters'];
      if (savedDeliveredLetters is Map) {
        for (final entry in savedDeliveredLetters.entries) {
          final savedDate = entry.key;
          final letterId = entry.value;
          if (savedDate is! String || letterId is! String) {
            continue;
          }

          final date = _tryParseDate(savedDate);
          if (date != null) {
            deliveredLetters[_formatDate(date)] = letterId;
          }
        }
      } else if (!decoded.containsKey('deliveredLetters')) {
        for (final entry in receivedLetters.entries) {
          final receivedDate = entry.value;
          if (receivedDate != null) {
            deliveredLetters.putIfAbsent(
              _formatDate(receivedDate),
              () => entry.key,
            );
          }
        }
      }

      return ReadLetterState(
        receivedLetters: receivedLetters,
        deliveredLetters: deliveredLetters,
      );
    } on FormatException {
      return null;
    }
  }

  DateTime? _tryParseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String _formatDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final year = normalizedDate.year.toString().padLeft(4, '0');
    final month = normalizedDate.month.toString().padLeft(2, '0');
    final day = normalizedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

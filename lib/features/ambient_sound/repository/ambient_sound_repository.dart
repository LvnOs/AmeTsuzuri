import 'package:shared_preferences/shared_preferences.dart';

typedef SetAmbientSoundEnabledOverride =
    Future<bool> Function(String key, bool value);

class AmbientSoundRepository {
  AmbientSoundRepository({this.setEnabledOverride});

  static const String _key = 'ambientSoundEnabled';

  final SetAmbientSoundEnabledOverride? setEnabledOverride;

  Future<bool> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.get(_key);
    return savedValue is bool ? savedValue : false;
  }

  Future<void> saveEnabled(bool isEnabled) async {
    final didSave = setEnabledOverride != null
        ? await setEnabledOverride!(_key, isEnabled)
        : await (await SharedPreferences.getInstance()).setBool(
            _key,
            isEnabled,
          );
    if (!didSave) {
      throw StateError('Failed to save ambient sound setting.');
    }
  }
}

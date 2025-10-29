import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

/// Loads translations from assets/i18n/*.json and merges them into a single map.
class JsonTranslations extends Translations {
  static final Map<String, Map<String, String>> _loaded = {};

  static Future<void> loadLocales(List<String> languageCodes) async {
    for (final code in languageCodes) {
      final path = 'assets/i18n/$code.json';
      try {
        final jsonStr = await rootBundle.loadString(path);
        final Map<String, dynamic> raw = json.decode(jsonStr);
        _loaded[code] = raw.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        // Ignore missing files; rely on fallback keys
      }
    }
  }

  /// Returns a snapshot of the currently loaded translation maps.
  static Map<String, Map<String, String>> loadedKeys() {
    return _loaded.map((k, v) => MapEntry(k, Map<String, String>.from(v)));
  }

  /// Merge an existing base keys map with the loaded JSON overrides.
  /// JSON values win.
  static Map<String, Map<String, String>> mergeWith(
    Map<String, Map<String, String>> base,
  ) {
    final merged = <String, Map<String, String>>{};
    // Start with base
    for (final entry in base.entries) {
      merged[entry.key] = Map<String, String>.from(entry.value);
    }
    // Overlay loaded
    for (final entry in _loaded.entries) {
      final lang = entry.key;
      final overrides = entry.value;
      merged.putIfAbsent(lang, () => {});
      merged[lang]!.addAll(overrides);
    }
    return merged;
  }

  JsonTranslations(this._keys);

  final Map<String, Map<String, String>> _keys;

  @override
  Map<String, Map<String, String>> get keys => _keys;
}

import 'package:get/get.dart';

/// Helper for parameterized translations with proper placeholder replacement
/// Since GetX's trParams may not work with JSON-loaded translations, this ensures replacement
extension CustomTrParams on String {
  /// Translates a string and replaces placeholders like {key} with values from params
  String trWithParams(Map<String, String> params) {
    String translated = tr;
    params.forEach((key, value) {
      translated = translated.replaceAll('{$key}', value);
    });
    return translated;
  }
}

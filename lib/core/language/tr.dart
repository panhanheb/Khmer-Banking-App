import 'package:flutter/widgets.dart';

import 'translations/en.dart';
import 'translations/km.dart';

/// Map-based translations.
///
/// ```dart
/// 'loginTitle'.tr                                  // "Welcome back" / "សូមស្វាគមន៍ការត្រឡប់មកវិញ"
/// 'resetLinkSent'.trParams({'email': email})      // fills {email}
/// ```
///
/// Add a string by putting the same key in every map under `translations/`.
/// A key missing from the current language falls back to English, then to the
/// key itself, so a typo shows up on screen instead of crashing.
class Tr {
  const Tr._();

  /// All languages, by language code.
  static const Map<String, Map<String, String>> keys = {'en': en, 'km': km};

  static const List<Locale> supportedLocales = [Locale('km'), Locale('en')];

  static String _languageCode = 'km';

  /// Current language (`km` or `en`).
  static String get languageCode => _languageCode;

  static String _supported(String code) => keys.containsKey(code) ? code : 'en';

  /// Sets the language before the first frame (no rebuild needed).
  static void init(String code) => _languageCode = _supported(code);

  /// Switches the language at runtime. Widgets read `.tr` while building, so
  /// the whole widget tree is then rebuilt (like a hot reload: navigation and
  /// widget state are kept).
  static void setLanguage(String code) {
    final next = _supported(code);
    if (next == _languageCode) return;
    _languageCode = next;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => WidgetsBinding.instance.reassembleApplication(),
    );
  }

  static String translate(String key) =>
      keys[_languageCode]?[key] ?? en[key] ?? key;
}

extension TrString on String {
  /// The translation of this key in the current language.
  String get tr => Tr.translate(this);

  /// Translation with `{placeholder}`s replaced by [params].
  String trParams(Map<String, String> params) {
    var text = tr;
    params.forEach((name, value) => text = text.replaceAll('{$name}', value));
    return text;
  }
}

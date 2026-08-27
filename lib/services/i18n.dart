import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight i18n that loads the SAME locale JSON files the web app uses
/// (en / am / om / ti) from assets and resolves dotted keys like
/// `dashboard.title` with `{{var}}` interpolation.
class AppLocalizations {
  AppLocalizations._();

  static final ValueNotifier<String> locale = ValueNotifier<String>('en');

  static const List<String> supportedLocales = ['en', 'am', 'om', 'ti'];
  static const Map<String, String> localeNames = {
    'en': 'English',
    'am': 'አማርኛ',
    'ti': 'ትግርኛ',
    'om': 'Afaan Oromoo',
  };

  static Map<String, dynamic> _strings = {};

  static String get currentLocale => locale.value;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('language');
    if (saved != null && supportedLocales.contains(saved)) {
      locale.value = saved;
    }
    await _loadLocale(locale.value);
  }

  static Future<void> setLocale(String code) async {
    if (!supportedLocales.contains(code)) return;
    locale.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
    await _loadLocale(code);
  }

  static Future<void> _loadLocale(String code) async {
    try {
      final raw = await rootBundle.loadString('assets/locales/$code.json');
      _strings = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      final raw = await rootBundle.loadString('assets/locales/en.json');
      _strings = jsonDecode(raw) as Map<String, dynamic>;
    }
  }

  /// Resolve `dashboard.title`, `login.errors.emailRequired`, etc.
  static String t(String key, {Map<String, dynamic> params = const {}}) {
    final raw = _lookup(_strings, key);
    if (raw == null) return key;
    var value = raw;
    for (final entry in params.entries) {
      value = value.replaceAll('{{${entry.key}}}', '${entry.value}');
    }
    return value;
  }

  static String? _lookup(Map<String, dynamic> map, String key) {
    final parts = key.split('.');
    dynamic current = map;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current is String ? current : null;
  }

  /// Pluralization helper: the web uses `key_one` / `key_other` suffixes.
  static String plural(String baseKey, int count) {
    final one = t('${baseKey}_one', params: {'count': count});
    if (!one.startsWith('${baseKey}_one')) return one; // resolved
    return t('${baseKey}_other', params: {'count': count});
  }
}

/// Convenience for widgets: `context.tr('key')`.
extension AppLocalizationExtension on BuildContext {
  String tr(String key, {Map<String, dynamic> params = const {}}) {
    return AppLocalizations.t(key, params: params);
  }
}

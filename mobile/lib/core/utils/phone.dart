import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../config/app_config_provider.dart';

part 'phone.g.dart';

/// Mainland-China phone number rules from `AppConfig.auth`.
///
/// Normalization mirrors the server: drop whitespace, dashes, dots and brackets, then strip
/// one leading country-code prefix (`+86`, `0086`, `86`, longest match first).
class PhoneRules {
  PhoneRules(AuthConfigDefaults config)
    : _pattern = RegExp(config.phonePattern),
      _prefixes = [...config.phonePrefixes]..sort((a, b) => b.length.compareTo(a.length));

  final RegExp _pattern;
  final List<String> _prefixes;

  static final RegExp _separators = RegExp(r'[\s\-.()（）]');

  String normalize(String input) {
    final compact = input.replaceAll(_separators, '');
    for (final prefix in _prefixes) {
      if (compact.startsWith(prefix) && compact.length > prefix.length) {
        return compact.substring(prefix.length);
      }
    }
    return compact;
  }

  /// True when the normalized [input] matches `AppConfig.auth.phonePattern`.
  bool isValid(String input) => _pattern.hasMatch(normalize(input));
}

@Riverpod(keepAlive: true)
PhoneRules phoneRules(Ref ref) => PhoneRules(ref.watch(appConfigProvider).auth);

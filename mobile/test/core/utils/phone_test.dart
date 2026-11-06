import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/utils/phone.dart';
import 'package:meeting/core/utils/server_url.dart';

import '../../helpers/test_config.dart';

void main() {
  final rules = PhoneRules(loadConfigFile('dev').auth);

  group('PhoneRules.normalize', () {
    test('strips country code prefixes', () {
      expect(rules.normalize('+8613800138000'), '13800138000');
      expect(rules.normalize('8613800138000'), '13800138000');
      expect(rules.normalize('008613800138000'), '13800138000');
    });

    test('strips spaces, dashes and brackets', () {
      expect(rules.normalize(' 138 0013 8000 '), '13800138000');
      expect(rules.normalize('138-0013-8000'), '13800138000');
      expect(rules.normalize('+86 (138) 0013-8000'), '13800138000');
    });

    test('keeps plain numbers', () {
      expect(rules.normalize('13800138000'), '13800138000');
    });
  });

  group('PhoneRules.isValid', () {
    test('accepts mainland mobile numbers in any accepted format', () {
      expect(rules.isValid('13800138000'), isTrue);
      expect(rules.isValid('+86 199-0000-1111'), isTrue);
    });

    test('rejects invalid numbers', () {
      expect(rules.isValid(''), isFalse);
      expect(rules.isValid('12800138000'), isFalse); // second digit must be 3-9
      expect(rules.isValid('1380013800'), isFalse); // 10 digits
      expect(rules.isValid('138001380001'), isFalse); // 12 digits
      expect(rules.isValid('1380013800a'), isFalse);
    });
  });

  group('server url', () {
    test('normalizes trailing slashes and blanks', () {
      expect(normalizeServerUrl(' https://a.example.com/// '), 'https://a.example.com');
      expect(normalizeServerUrl('   '), isNull);
      expect(normalizeServerUrl(null), isNull);
    });

    test('validates scheme and host', () {
      expect(isValidServerUrl('http://10.0.2.2:8000'), isTrue);
      expect(isValidServerUrl('https://meeting.example.com/'), isTrue);
      expect(isValidServerUrl('meeting.example.com'), isFalse);
      expect(isValidServerUrl('ftp://x'), isFalse);
    });
  });
}

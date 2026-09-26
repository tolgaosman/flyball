import 'package:flutter/widgets.dart';
import 'package:flyball/utils/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextFold', () {
    test('fold lowercases plain ASCII', () {
      expect(TextFold.fold('Messi'), 'messi');
    });

    test('fold strips Turkish dotted/dotless i correctly', () {
      expect(TextFold.fold('İlkay'), 'ilkay');
      expect(TextFold.fold('Atatürk'), 'ataturk');
      expect(TextFold.fold('ılık'), 'ilik');
    });

    test('fold strips accents so "ozil" matches "Özil"', () {
      expect(TextFold.fold('Özil'), 'ozil');
    });

    test('contains matches regardless of case and accents', () {
      expect(TextFold.contains('İsmail Jakobs', 'ismail'), isTrue);
      expect(TextFold.contains('Mesut Özil', 'ozil'), isTrue);
      expect(TextFold.contains('Wilfried Singo', 'singo'), isTrue);
      expect(TextFold.contains('Wilfried Singo', 'zzz'), isFalse);
    });
  });

  group('LocaleAwareCase.toUpperCaseFor', () {
    test('Turkish locale uppercases dotted i to İ', () {
      expect('ismail'.toUpperCaseFor(const Locale('tr')), 'İSMAİL');
    });

    test('English locale uses default uppercasing', () {
      expect('ismail'.toUpperCaseFor(const Locale('en')), 'ISMAIL');
    });
  });
}

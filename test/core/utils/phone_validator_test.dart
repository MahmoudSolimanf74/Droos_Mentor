import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    test('Valid Egyptian phone numbers should return null (no error)', () {
      expect(PhoneValidator.validateEgyptianPhone('01012345678'), isNull);
      expect(PhoneValidator.validateEgyptianPhone('01123456789'), isNull);
      expect(PhoneValidator.validateEgyptianPhone('01234567890'), isNull);
      expect(PhoneValidator.validateEgyptianPhone('01545678901'), isNull);
    });

    test('Invalid prefixes should return "دخل الرقم صح يلا "', () {
      expect(PhoneValidator.validateEgyptianPhone('01312345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('01412345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('01612345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('01712345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('01812345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('01912345678'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('02012345678'), equals('دخل الرقم صح يلا '));
    });

    test('Numbers with wrong length should return "دخل الرقم صح يلا "', () {
      expect(PhoneValidator.validateEgyptianPhone('0101234567'), equals('دخل الرقم صح يلا ')); // 10 digits
      expect(PhoneValidator.validateEgyptianPhone('010123456789'), equals('دخل الرقم صح يلا ')); // 12 digits
      expect(PhoneValidator.validateEgyptianPhone('010'), equals('دخل الرقم صح يلا '));
    });

    test('Numbers with non-digit characters should return "دخل الرقم صح يلا "', () {
      expect(PhoneValidator.validateEgyptianPhone('0101234567a'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('010123-4567'), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('010 1234567'), equals('دخل الرقم صح يلا '));
    });

    test('Empty / null values handling', () {
      expect(PhoneValidator.validateEgyptianPhone(null, isRequired: false), isNull);
      expect(PhoneValidator.validateEgyptianPhone('', isRequired: false), isNull);
      expect(PhoneValidator.validateEgyptianPhone('   ', isRequired: false), isNull);

      expect(PhoneValidator.validateEgyptianPhone(null, isRequired: true), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('', isRequired: true), equals('دخل الرقم صح يلا '));
      expect(PhoneValidator.validateEgyptianPhone('   ', isRequired: true), equals('دخل الرقم صح يلا '));
    });

    test('PhoneValidator.formatForWhatsApp formats correctly', () {
      expect(PhoneValidator.formatForWhatsApp('01012345678'), equals('201012345678'));
      expect(PhoneValidator.formatForWhatsApp('201012345678'), equals('201012345678'));
      expect(PhoneValidator.formatForWhatsApp('00201012345678'), equals('201012345678'));
    });
  });
}

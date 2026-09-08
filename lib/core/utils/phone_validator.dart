/// Utility class for validating Egyptian mobile numbers.
/// Valid prefixes: 010 (Vodafone), 011 (Etisalat), 012 (Orange), 015 (WE)
/// Length: Exactly 11 digits
/// Content: Digits only
class PhoneValidator {
  PhoneValidator._();

  static final RegExp _egyptianPhoneRegex = RegExp(r'^01[0125][0-9]{8}$');

  static const String errorMessage = 'دخل الرقم صح يلا ';

  /// Validates a phone string.
  /// Returns `null` if valid (or empty when [isRequired] is false).
  /// Returns `'دخل الرقم صح يلا '` if invalid.
  static String? validateEgyptianPhone(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) {
        return errorMessage;
      }
      return null;
    }

    final trimmed = value.trim();

    // Check if it matches exactly 11 digits starting with 010, 011, 012, or 015
    if (!_egyptianPhoneRegex.hasMatch(trimmed)) {
      return errorMessage;
    }

    return null;
  }

  /// Checks if a given string is a valid Egyptian phone number.
  static bool isValid(String? value) {
    if (value == null) return false;
    return _egyptianPhoneRegex.hasMatch(value.trim());
  }

  /// Formats Egyptian phone number to standard international format without '+' or spaces for WhatsApp wa.me link.
  /// Example: '01012345678' -> '201012345678'
  static String formatForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0020')) {
      digits = digits.substring(2);
    } else if (digits.startsWith('20') && digits.length == 12) {
      return digits;
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = '2$digits';
    }
    return digits;
  }
}

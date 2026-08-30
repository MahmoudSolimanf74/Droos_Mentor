import 'dart:math';
import 'package:uuid/uuid.dart';

class TokenGenerator {
  TokenGenerator._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();
  static const _uuid = Uuid();

  /// Generate human-readable join code e.g. "CP-8X2M"
  static String generateJoinCode([int length = 6]) {
    final code = List.generate(length, (index) => _chars[_random.nextInt(_chars.length)]).join();
    return 'CP-$code';
  }

  /// Generate group join code e.g. "GRP-8X2M9"
  static String generateGroupCode([int length = 5]) {
    final code = List.generate(length, (index) => _chars[_random.nextInt(_chars.length)]).join();
    return 'GRP-$code';
  }

  /// Generate student code e.g. "STU-8X2M9K"
  static String generateStudentCode([int length = 6]) {
    final code = List.generate(length, (index) => _chars[_random.nextInt(_chars.length)]).join();
    return 'STU-$code';
  }

  /// Generate secure invite token for QR code e.g. "grp_inv_9f8c7..."
  static String generateInviteToken() {
    final randomPart = _uuid.v4().replaceAll('-', '');
    return 'cpt_inv_$randomPart';
  }
}

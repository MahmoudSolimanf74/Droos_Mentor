import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/core/utils/json_validator.dart';
import 'package:teacher/core/utils/token_generator.dart';

void main() {
  group('TokenGenerator Tests', () {
    test('generateJoinCode generates code with CP- prefix', () {
      final code = TokenGenerator.generateJoinCode();
      expect(code.startsWith('CP-'), isTrue);
      expect(code.length, equals(9));
    });

    test('generateInviteToken generates unique invite token with cpt_inv_ prefix', () {
      final token1 = TokenGenerator.generateInviteToken();
      final token2 = TokenGenerator.generateInviteToken();
      expect(token1.startsWith('cpt_inv_'), isTrue);
      expect(token1, isNot(equals(token2)));
    });
  });

  group('JsonExamValidator Tests', () {
    test('validates valid exam JSON correctly', () {
      const validJson = '''
      {
        "title": "اختبار بايثون",
        "duration_minutes": 25,
        "questions": [
          {
            "question": "ما هو نوع البيانات 10؟",
            "options": ["int", "String", "bool", "float"],
            "correct_answer": "int"
          }
        ]
      }
      ''';

      final result = JsonExamValidator.validate(validJson);
      expect(result.isValid, isTrue);
      expect(result.parsedExam, isNotNull);
      expect(result.parsedExam!.title, equals('اختبار بايثون'));
      expect(result.parsedExam!.questions.length, equals(1));
    });

    test('detects missing correct_answer from options', () {
      const invalidJson = '''
      {
        "title": "اختبار غير صالح",
        "duration_minutes": 20,
        "questions": [
          {
            "question": "سؤال تجريبي",
            "options": ["أ", "ب", "ج"],
            "correct_answer": "د"
          }
        ]
      }
      ''';

      final result = JsonExamValidator.validate(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errorList.isNotEmpty, isTrue);
    });
  });
}

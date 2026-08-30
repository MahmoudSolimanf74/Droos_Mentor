import 'dart:convert';

class ExamQuestionParsed {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int sortOrder;

  const ExamQuestionParsed({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'sort_order': sortOrder,
      };
}

class ExamParsed {
  final String title;
  final int durationMinutes;
  final List<ExamQuestionParsed> questions;

  const ExamParsed({
    required this.title,
    required this.durationMinutes,
    required this.questions,
  });
}

class JsonValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<String> errorList;
  final ExamParsed? parsedExam;

  List<String> get errors => errorList;

  const JsonValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorList = const [],
    this.parsedExam,
  });

  factory JsonValidationResult.failure(String message, [List<String> errors = const []]) {
    return JsonValidationResult(
      isValid: false,
      errorMessage: message,
      errorList: errors.isEmpty ? [message] : errors,
    );
  }

  factory JsonValidationResult.success(ExamParsed exam) {
    return JsonValidationResult(
      isValid: true,
      parsedExam: exam,
    );
  }
}

class JsonExamValidator {
  JsonExamValidator._();

  static JsonValidationResult validate(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return JsonValidationResult.failure('محتوى JSON فارغ');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawJson);
    } catch (e) {
      return JsonValidationResult.failure('خطأ في بناء جملة JSON: ${e.toString()}');
    }

    if (decoded is! Map<String, dynamic>) {
      return JsonValidationResult.failure('يجب أن يكون ملف JSON كائناً (Object) رئيسياً');
    }

    final errors = <String>[];

    // Validate title
    final title = decoded['title'];
    if (title == null || title is! String || title.trim().isEmpty) {
      errors.add('حقل "title" مفقود أو غير نصي');
    }

    // Validate duration
    final duration = decoded['duration_minutes'];
    int durationMinutes = 30;
    if (duration != null) {
      if (duration is int) {
        durationMinutes = duration;
      } else if (duration is String) {
        final parsed = int.tryParse(duration);
        if (parsed != null) {
          durationMinutes = parsed;
        } else {
          errors.add('حقل "duration_minutes" يجب أن يكون رقماً صحيحاً');
        }
      } else {
        errors.add('حقل "duration_minutes" يجب أن يكون رقماً صحيحاً');
      }
    }

    // Validate questions
    final questionsRaw = decoded['questions'];
    if (questionsRaw == null || questionsRaw is! List) {
      errors.add('حقل "questions" مفقود أو ليس قائمة (Array)');
      return JsonValidationResult.failure(errors.first, errors);
    }

    if (questionsRaw.isEmpty) {
      errors.add('قائمة الأسئلة "questions" لا تحتوي على أي سؤال');
    }

    final parsedQuestions = <ExamQuestionParsed>[];

    for (int i = 0; i < questionsRaw.length; i++) {
      final qIndex = i + 1;
      final item = questionsRaw[i];

      if (item is! Map) {
        errors.add('السؤال رقم $qIndex ليس كائناً صالحاً');
        continue;
      }

      final qText = item['question'];
      if (qText == null || qText is! String || qText.trim().isEmpty) {
        errors.add('السؤال رقم $qIndex: نص السؤال "question" غير موجود أو فارغ');
      }

      final optionsRaw = item['options'];
      if (optionsRaw == null || optionsRaw is! List) {
        errors.add('السؤال رقم $qIndex: قائمة الخيارات "options" غير موجودة أو غير صالحة');
        continue;
      }

      if (optionsRaw.length < 2) {
        errors.add('السؤال رقم $qIndex: يجب أن يحتوي على خيارين على الأقل');
      }

      final optionsList = <String>[];
      for (final opt in optionsRaw) {
        if (opt != null) {
          optionsList.add(opt.toString().trim());
        }
      }

      final correctAnswer = item['correct_answer'];
      if (correctAnswer == null || correctAnswer.toString().trim().isEmpty) {
        errors.add('السؤال رقم $qIndex: الإجابة الصحيحة "correct_answer" غير محددة');
      } else {
        final correctStr = correctAnswer.toString().trim();
        if (!optionsList.contains(correctStr)) {
          errors.add('السؤال رقم $qIndex: الإجابة الصحيحة ("$correctStr") غير مطابقة لأي من الخيارات المتاحة');
        }
      }

      if (errors.isEmpty) {
        parsedQuestions.add(
          ExamQuestionParsed(
            question: qText.toString().trim(),
            options: optionsList,
            correctAnswer: correctAnswer.toString().trim(),
            sortOrder: i,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return JsonValidationResult.failure('تم العثور على أخطاء في ملف JSON', errors);
    }

    return JsonValidationResult.success(
      ExamParsed(
        title: title.toString().trim(),
        durationMinutes: durationMinutes,
        questions: parsedQuestions,
      ),
    );
  }
}

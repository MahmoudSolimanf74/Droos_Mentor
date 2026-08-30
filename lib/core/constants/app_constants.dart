class AppConstants {
  AppConstants._();

  static const String appVersion = '1.0.0';
  static const String lessonFilesBucket = 'lesson-files';

  // Grades in High-School Egypt/Arab Curriculum
  static const List<String> highSchoolGrades = [
    'الصف الأول الثانوي',
    'الصف الثاني الثانوي (علمي)',
    'الصف الثاني الثانوي (أدبي)',
    'الصف الثالث الثانوي (علمي علوم)',
    'الصف الثالث الثانوي (علمي رياضة)',
    'الصف الثالث الثانوي (أدبي)',
  ];

  // Storage max upload size (e.g. 50 MB)
  static const int maxFileSizeBytes = 50 * 1024 * 1024;
}

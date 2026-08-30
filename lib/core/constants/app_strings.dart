/// Application Arabic UI Strings & Labels
class AppStrings {
  AppStrings._();

  static const String appName = 'مدرستي';
  static const String appTagline = 'نظام إدارة الدروس الخصوصية';

  // Navigation
  static const String navDashboard = 'لوحة التحكم';
  static const String navGroups = 'المجموعات';
  static const String navGrades = 'المجموعات والصفوف';
  static const String navCurriculum = 'المنهج';
  static const String navExams = 'الامتحانات';
  static const String navAttendance = 'الحضور';
  static const String navAssignments = 'الواجبات';
  static const String navPerformance = 'الأداء';
  static const String navSettings = 'الإعدادات';

  // Auth
  static const String loginTitle = 'مرحباً بك يا أستاذ';
  static const String loginSubtitle = 'سجّل الدخول للوصول إلى لوحة تحكم صفوفك وطلابك';
  static const String signInWithGoogle = 'الدخول بحساب Google';
  static const String orUseDemoMode = 'الدخول بوضع المعاينة (Demo Mode)';
  static const String demoModeDescription = 'تتيح لك تجربة كامل خصائص التطبيق دون اتصال مباشر';
  static const String roleCheckFailed = 'هذا الحساب ليس مسجلاً كمعلم. لا يمكن تسجيل الدخول.';
  static const String logout = 'تسجيل الخروج';
  static const String logoutConfirmation = 'هل أنت متأكد من رغبتك في تسجيل الخروج؟';

  // Common Actions
  static const String add = 'إضافة';
  static const String edit = 'تعديل';
  static const String delete = 'حذف';
  static const String save = 'حفظ';
  static const String cancel = 'إلغاء';
  static const String search = 'بحث...';
  static const String filter = 'تصفية';
  static const String confirm = 'تأكيد';
  static const String viewDetails = 'عرض التفاصيل';
  static const String refresh = 'تحديث';
  static const String close = 'إغلاق';
  static const String copy = 'نسخ';
  static const String copied = 'تم النسخ';
  static const String requiredField = 'هذا الحقل مطلوب';

  // Dashboard
  static const String teacherDashboard = 'لوحة التحكم';
  static const String totalStudents = 'إجمالي الطلاب';
  static const String activeGroups = 'عدد المجموعات';
  static const String todayAttendanceRate = 'متوسط الحضور';
  static const String upcomingExams = 'امتحانات نشطة';
  static const String completedLessons = 'دروس مكتملة';
  static const String quickActions = 'إجراءات سريعة';
  static const String recentSessions = 'آخر الحصص';
  static const String groupsSummary = 'نظرة عامة على المجموعات';
  static const String recentActivity = 'آخر النشاطات';

  // Grades & Groups
  static const String createGroup = 'مجموعة جديدة';
  static const String editGroup = 'تعديل المجموعة';
  static const String groupName = 'اسم المجموعة';
  static const String grade = 'المرحلة الدراسية';
  static const String joinCode = 'كود الانضمام';
  static const String qrCode = 'رمز QR';
  static const String groupQr = 'رمز الاستجابة السريع (QR)';
  static const String studentsCount = 'عدد الطلاب';
  static const String noGroupsYet = 'لا توجد مجموعات بعد';
  static const String noGroupsSubtitle = 'ابدأ بإنشاء أول مجموعة لطلابك لإدارة المنهج والدروس';
  static const String deleteGroupWarning = 'هل أنت متأكد من حذف هذه المجموعة؟';

  // Tabs
  static const String tabOverview = 'نظرة عامة';
  static const String tabStudents = 'الطلاب';
  static const String tabAttendance = 'الحضور';
  static const String tabHomework = 'الواجبات';
  static const String tabExams = 'الامتحانات';
  static const String tabPerformance = 'الأداء';
  static const String tabQr = 'كود الانضمام';
  static const String tabStats = 'إحصائيات';

  // Students
  static const String studentName = 'اسم الطالب';
  static const String studentCode = 'كود الطالب';
  static const String phone = 'رقم الهاتف';
  static const String parentPhone = 'هاتف ولي الأمر';
  static const String attendanceRate = 'نسبة الحضور';
  static const String homeworkRate = 'نسبة الواجبات';
  static const String examAverage = 'متوسط الاختبارات';
  static const String studentStatus = 'حالة الطالب';
  static const String addStudent = 'إضافة طالب';
  static const String removeStudent = 'استبعاد الطالب';
  static const String joinedAt = 'تاريخ الانضمام';

  // Statuses
  static const String active = 'نشط';
  static const String inactive = 'غير نشط';
  static const String statusActive = 'نشط الآن';
  static const String statusInactive = 'غير نشط';
  static const String statusScheduled = 'مجدول';
  static const String statusCompleted = 'منتهي';
  static const String statusPresent = 'حاضر';
  static const String statusAbsent = 'غائب';
  static const String statusLate = 'متأخر';
  static const String statusDone = 'تم الإنجاز';
  static const String statusNotDone = 'لم يُنجز';

  // Curriculum
  static const String units = 'الوحدات الدراسية';
  static const String lessons = 'الدروس';
  static const String addUnit = 'إضافة وحدة';
  static const String addLesson = 'إضافة درس';
  static const String uploadFile = 'رفع ملف';
  static const String fileTitle = 'عنوان الملف';
  static const String noFiles = 'لا توجد ملفات مرفوعة';
  static const String selectLessonPrompt = 'اختر درساً لعرض ملفاته';

  // Attendance
  static const String sessions = 'الحصص';
  static const String newSession = 'حصة جديدة';
  static const String takeAttendance = 'تسجيل الحضور';
  static const String sessionTitle = 'عنوان الحصة';
  static const String sessionDate = 'تاريخ الحصة';
  static const String saveSession = 'حفظ الحصة';
  static const String attendanceSaved = 'تم حفظ الحضور';
  static const String markAllPresent = 'تسجيل الكل حاضر';

  // Homework
  static const String assignments = 'الواجبات';
  static const String newAssignment = 'واجب جديد';
  static const String dueDate = 'موعد التسليم';
  static const String completed = 'أنجز الواجب';
  static const String notCompleted = 'لم ينجز';
  static const String homeworkSaved = 'تم حفظ حالة الواجب';
  static const String markHomework = 'رصد الواجبات';
  static const String markAllDone = 'تسجيل الكل تم';

  // Exams
  static const String examResults = 'نتائج الامتحان';
  static const String officialAttempt = 'محاولة رسمية';

  // Performance Matrix
  static const String performanceMatrix = 'جدول الأداء';
  static const String performanceSubtitle = 'مقارنة شاملة لأداء الطلاب — حضور وواجبات وامتحانات';
  static const String scoreAverage = 'المتوسط';
  static const String excellent = 'ممتاز (80%+)';
  static const String average = 'متوسط (60-79%)';
  static const String poor = 'ضعيف (أقل من 60%)';
}

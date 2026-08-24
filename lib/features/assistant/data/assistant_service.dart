import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/domain/dashboard_models.dart';

class AssistantMessage {
  const AssistantMessage({
    required this.text,
    required this.isFromUser,
    this.suggestions = const [],
  });

  final String text;
  final bool isFromUser;
  final List<String> suggestions;
}

class AssistantService {
  AssistantService(this._client);

  final SupabaseClient _client;

  Future<String> respond(String input) async {
    final String q = input.trim();
    if (q.isEmpty) return 'اكتب سؤالاً وأنا أساعدك 😊';

    if (_has(q, ['مرحبا', 'هلا', 'السلام', 'هاي', 'أهلا', 'اهلا'])) {
      return 'أهلاً بك! 👋 أنا مساعدك الذكي لنظام الحضور.\n'
          'اسألني عن إحصائيات اليوم، وضع طالب معين، أو الطلاب الذين يحتاجون متابعة.';
    }

    if (_has(q, ['مساعدة', 'ساعدني', 'وش تسوي', 'وش تقدر', 'قدرات'])) {
      return 'أقدر أساعدك في:\n'
          '📊 إحصائيات حضور اليوم\n'
          '📈 نسبة الحضور الأسبوعية\n'
          '👤 وضع طالب معين (اكتب اسمه)\n'
          '⚠️ الطلاب الذين يحتاجون متابعة\n'
          '❌ قائمة الغائبين اليوم\n'
          '🏫 إحصائيات صف معين';
    }

    if (_has(q, ['غائب', 'الغائبين', 'ما حضر', 'ما حضروا'])) {
      return await _absentToday();
    }

    if (_has(q, ['متابعة', 'خطر', 'متعثر', 'متأخرين', 'تحذير'])) {
      return await _riskyStudents();
    }

    if (_has(q, ['نسبة'])) {
      return await _attendanceRate();
    }

    if (_has(q, ['اليوم', 'الان', 'الآن', 'إحصائية', 'احصائية', 'ملخص', 'كم طالب'])) {
      return await _todaySummary();
    }

    if (_has(q, ['أسبوع', 'اسبوع', 'أسبوعية', 'اسبوعية', 'آخر أيام'])) {
      return await _weeklySummary();
    }

    final String? studentName = _extractStudentName(q);
    if (studentName != null) {
      return await _studentStatus(studentName);
    }

    final String? className = await _extractClassName(q);
    if (className != null) {
      return await _classSummary(className);
    }

    return 'ما فهمت سؤالك تماماً 🤔\n'
        'جرب تسأل:\n'
        '• "كم طالب حاضر اليوم؟"\n'
        '• "وضع الطالب أحمد"\n'
        '• "الغائبين اليوم"\n'
        '• "الطلاب الذين يحتاجون متابعة"';
  }

  bool _has(String input, List<String> keywords) {
    for (final String k in keywords) {
      if (input.contains(k)) return true;
    }
    return false;
  }

  String? _extractStudentName(String input) {
    final RegExp studentTrigger = RegExp(r'(طالب|الطالب|وضع|حالة|سجل)');
    if (!studentTrigger.hasMatch(input)) return null;
    final List<String> stopWords = [
      'الطالب', 'طالب', 'وضع', 'حالة', 'سجل', 'كم', 'ما', 'من', 'في',
      'عن', 'ايه', 'إيه', 'هو', 'اليوم', 'الأسبوع', 'الاسبوع', 'شو',
    ];
    String cleaned = input;
    for (final String w in stopWords) {
      cleaned = cleaned.replaceAll(w, ' ');
    }
    cleaned = cleaned
        .replaceAll(RegExp(r'[؟?.!،,]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.trim().length >= 2)
        .join(' ')
        .trim();
    if (cleaned.isEmpty || cleaned.length < 2) return null;
    return cleaned;
  }

  Future<String?> _extractClassName(String input) async {
    if (!_has(input, ['صف', 'الصف', 'صفوف'])) return null;
    final rows = await _client.from('classes').select('name');
    for (final Map<String, dynamic> row in rows) {
      final String name = row['name'] as String;
      if (input.contains(name)) return name;
    }
    return null;
  }

  Future<Map<String, int>> _statusCountsForDay(DateTime day) async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(day);
    final rows = await _client
        .from('attendance_logs')
        .select('status')
        .eq('attendance_date', dateStr);
    final Map<String, int> counts = {
      'present': 0,
      'late': 0,
      'absent': 0,
    };
    for (final Map<String, dynamic> row in rows) {
      final String s = (row['status'] ?? 'absent') as String;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  Future<String> _todaySummary() async {
    final Map<String, int> c = await _statusCountsForDay(DateTime.now());
    final int total = c['present']! + c['late']! + c['absent']!;
    if (total == 0) {
      return 'لم يتم تسجيل أي حضور اليوم بعد 📝\n'
          'روح لتبويب "الحضور" وسجل حضور الطلاب.';
    }
    final double rate = (c['present']! + c['late']!) / total * 100;
    return '📊 إحصائيات اليوم:\n\n'
        '✅ حاضر: ${c['present']}\n'
        '⏰ متأخر: ${c['late']}\n'
        '❌ غائب: ${c['absent']}\n'
        '📈 نسبة الحضور: ${rate.toStringAsFixed(1)}%';
  }

  Future<String> _attendanceRate() async {
    final Map<String, int> today = await _statusCountsForDay(DateTime.now());
    final int totalToday =
        today['present']! + today['late']! + today['absent']!;
    final String weekLine = await _weekRateLine();
    if (totalToday == 0) return 'ما فيه حضور مسجل اليوم.\n$weekLine';
    final double rateToday =
        (today['present']! + today['late']!) / totalToday * 100;
    return '📈 نسبة حضور اليوم: ${rateToday.toStringAsFixed(1)}%\n$weekLine';
  }

  Future<String> _weekRateLine() async {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final rows = await _client
        .from('attendance_logs')
        .select('status')
        .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from));
    int present = 0, late = 0, absent = 0;
    for (final Map<String, dynamic> row in rows) {
      final String s = (row['status'] ?? 'absent') as String;
      if (s == 'present') {
        present++;
      } else if (s == 'late') {
        late++;
      } else {
        absent++;
      }
    }
    final int total = present + late + absent;
    if (total == 0) return '';
    final double rate = (present + late) / total * 100;
    return '📅 نسبة آخر 7 أيام: ${rate.toStringAsFixed(1)}%';
  }

  Future<String> _weeklySummary() async {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    final rows = await _client
        .from('attendance_logs')
        .select('status')
        .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from));
    int present = 0, late = 0, absent = 0;
    for (final Map<String, dynamic> row in rows) {
      final String s = (row['status'] ?? 'absent') as String;
      if (s == 'present') {
        present++;
      } else if (s == 'late') {
        late++;
      } else {
        absent++;
      }
    }
    final int total = present + late + absent;
    if (total == 0) return 'ما فيه سجلات في آخر 7 أيام.';
    final double rate = (present + late) / total * 100;
    return '📈 ملخص آخر 7 أيام:\n\n'
        '✅ حاضر: $present\n'
        '⏰ متأخر: $late\n'
        '❌ غائب: $absent\n'
        '📊 النسبة العامة: ${rate.toStringAsFixed(1)}%';
  }

  Future<String> _absentToday() async {
    final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await _client
        .from('attendance_logs')
        .select('students(full_name, classes(name))')
        .eq('attendance_date', dateStr)
        .eq('status', 'absent');
    if (rows.isEmpty) {
      return 'ممتاز! ✨ ما فيه غائبين اليوم — جميع الطلاب حاضرين 👏';
    }
    final StringBuffer buffer = StringBuffer('❌ الغائبون اليوم (${rows.length}):\n\n');
    for (final Map<String, dynamic> row in rows) {
      final Map<String, dynamic>? student =
          row['students'] as Map<String, dynamic>?;
      final String name = (student?['full_name'] ?? '؟') as String;
      final String className =
          ((student?['classes'] as Map<String, dynamic>?)?['name'] ?? '')
              as String;
      buffer.writeln(
          className.isEmpty ? '• $name' : '• $name ($className)');
    }
    return buffer.toString();
  }

  Future<String> _riskyStudents() async {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final rows = await _client
        .from('attendance_logs')
        .select('status, students(full_name)')
        .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from));

    final Map<String, Map<String, int>> byStudent = {};
    for (final Map<String, dynamic> row in rows) {
      final String name =
          ((row['students'] as Map<String, dynamic>?)?['full_name'] ?? '؟')
              as String;
      final String s = (row['status'] ?? 'absent') as String;
      byStudent.putIfAbsent(name, () => {'present': 0, 'late': 0, 'absent': 0});
      byStudent[name]![s] = (byStudent[name]![s] ?? 0) + 1;
    }

    final List<StudentRisk> risks = byStudent.entries.map((e) {
      final int absent = e.value['absent'] ?? 0;
      final int total =
          (e.value['present'] ?? 0) + (e.value['late'] ?? 0) + absent;
      return StudentRisk(
          studentName: e.key, absentDays: absent, totalDays: total);
    }).where((r) => r.level != RiskLevel.low).toList()
      ..sort((a, b) => b.absenceRate.compareTo(a.absenceRate));

    if (risks.isEmpty) {
      return 'أخبار رائعة! ✨ جميع الطلاب منتظمون — ما فيه أحد يحتاج متابعة 👏';
    }
    final StringBuffer buffer = StringBuffer(
        '⚠️ طلاب يحتاجون متابعة (${risks.length}):\n\n');
    for (final StudentRisk r in risks.take(8)) {
      buffer.writeln(
          '${r.level == RiskLevel.high ? '🔴' : '🟡'} ${r.studentName} — '
          'غاب ${r.absentDays} من ${r.totalDays} يوم '
          '(${(r.absenceRate * 100).toStringAsFixed(0)}%) — ${r.level.labelAr}');
    }
    return buffer.toString();
  }

  Future<String> _studentStatus(String name) async {
    final rows = await _client
        .from('students')
        .select('id, full_name, classes(name)')
        .ilike('full_name', '%$name%')
        .limit(5);

    if (rows.isEmpty) {
      return 'ما لقيت طالب باسم "$name" 🤷\nتأكد من الاسم وحاول مرة ثانية.';
    }
    if (rows.length > 1) {
      final StringBuffer buffer = StringBuffer('لقيت أكثر من طالب، أي واحد تقصد؟\n\n');
      for (final Map<String, dynamic> row in rows) {
        buffer.writeln('• ${row['full_name']}');
      }
      return buffer.toString();
    }

    final Map<String, dynamic> student = rows.first;
    final String fullName = student['full_name'] as String;
    final String className =
        ((student['classes'] as Map<String, dynamic>?)?['name'] ?? '') as String;

    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final logs = await _client
        .from('attendance_logs')
        .select('status')
        .eq('student_id', student['id'] as int)
        .gte('attendance_date', DateFormat('yyyy-MM-dd').format(from));

    int present = 0, late = 0, absent = 0;
    for (final Map<String, dynamic> row in logs) {
      final String s = (row['status'] ?? 'absent') as String;
      if (s == 'present') {
        present++;
      } else if (s == 'late') {
        late++;
      } else {
        absent++;
      }
    }
    final int total = present + late + absent;
    if (total == 0) {
      return '👤 $fullName ($className)\n\nما فيه سجلات حضور له في آخر 30 يوم.';
    }

    final StudentRisk risk = StudentRisk(
        studentName: fullName, absentDays: absent, totalDays: total);
    final double rate = (present + late) / total * 100;
    final String emoji = switch (risk.level) {
      RiskLevel.low => '🟢',
      RiskLevel.medium => '🟡',
      RiskLevel.high => '🔴',
    };

    return '👤 $fullName ($className)\n\n'
        'آخر 30 يوم:\n'
        '✅ حاضر: $present\n'
        '⏰ متأخر: $late\n'
        '❌ غائب: $absent\n'
        '📈 نسبة الحضور: ${rate.toStringAsFixed(1)}%\n\n'
        '$emoji التقييم: ${risk.level.labelAr}';
  }

  Future<String> _classSummary(String className) async {
    final classRows = await _client
        .from('classes')
        .select('id, name')
        .eq('name', className)
        .limit(1);
    if (classRows.isEmpty) return 'ما لقيت صف باسم "$className".';

    final int classId = classRows.first['id'] as int;
    final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = await _client
        .from('attendance_logs')
        .select('status, students!inner(class_id)')
        .eq('attendance_date', dateStr)
        .eq('students.class_id', classId);

    if (rows.isEmpty) {
      return 'ما فيه حضور مسجل اليوم لصف "$className" 📝';
    }
    int present = 0, late = 0, absent = 0;
    for (final Map<String, dynamic> row in rows) {
      final String s = (row['status'] ?? 'absent') as String;
      if (s == 'present') {
        present++;
      } else if (s == 'late') {
        late++;
      } else {
        absent++;
      }
    }
    final int total = present + late + absent;
    final double rate = (present + late) / total * 100;
    return '🏫 صف "$className" — اليوم:\n\n'
        '✅ حاضر: $present\n'
        '⏰ متأخر: $late\n'
        '❌ غائب: $absent\n'
        '📈 النسبة: ${rate.toStringAsFixed(1)}%';
  }
}

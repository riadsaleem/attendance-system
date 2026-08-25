import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/times_provider.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../staff/domain/staff_models.dart';
import '../../staff/presentation/staff_screen.dart';
import '../../university/presentation/university_screen.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String routePath = '/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<DashboardData> data = ref.watch(dashboardProvider);
    final AsyncValue<UserProfile?> profile = ref.watch(currentProfileProvider);
    final AppTimes times = ref.watch(appTimesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً ${profile.valueOrNull?.fullName ?? ''} 👋',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now()),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assistant'),
        tooltip: 'المساعد الذكي',
        child: const Icon(Icons.smart_toy_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(dashboardProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _SectionGrid(theme: theme, profile: profile.valueOrNull),
            const SizedBox(height: 14),
            _ShiftTimesCard(theme: theme, times: times),
            const SizedBox(height: 20),
            Text(
              'حضور اليوم',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            data.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(dashboardProvider),
              ),
              data: (DashboardData d) => Column(
                children: [
                  _TodayCard(theme: theme, today: d.today),
                  const SizedBox(height: 16),
                  _WeekChart(theme: theme, week: d.week),
                  const SizedBox(height: 16),
                  _RisksCard(theme: theme, risks: d.risks),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'تطوير: رياض سليم © 2026',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.theme, this.profile});

  final ThemeData theme;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final bool staffOnly = profile?.isStaffOnly ?? false;
    final bool university = profile?.isUniversity ?? false;

    final List<_SectionCardData> sections = [
      _SectionCardData(
        title: 'الموظفون',
        subtitle: 'إدارة الموظفين وتفاصيلهم',
        icon: Icons.badge_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => _openStaff(context, StaffCategory.employee),
      ),
      if (!staffOnly)
        _SectionCardData(
          title: 'الطلاب الجامعين',
          subtitle: university ? 'الكليات والتخصصات' : 'قيد الإنشاء',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFFF59E0B),
          onTap: university
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const UniversityScreen()),
                  )
              : () => showUnderConstruction(context),
        ),
      _SectionCardData(
        title: 'الإحصائيات',
        subtitle: 'تقارير شاملة وتحليلات',
        icon: Icons.query_stats_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => context.go('/reports'),
      ),
      if (!staffOnly)
        _SectionCardData(
          title: 'الطلاب',
          subtitle: 'إدارة الطلاب والصفوف والحضور',
          icon: Icons.school_rounded,
          color: const Color(0xFF16A34A),
          onTap: () => context.go('/students'),
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: sections
          .map((s) => _SectionCard(theme: theme, data: s))
          .toList(),
    );
  }

  void _openStaff(BuildContext context, StaffCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StaffScreen(category: category),
      ),
    );
  }
}

void showUnderConstruction(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('قيد الإنشاء 🚧'),
      content: const Text(
          'قسم الطلاب الجامعين تحت التطوير — سيتم إطلاقه في تحديث قريب.'),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('حسناً'),
        ),
      ],
    ),
  );
}

class _SectionCardData {
  const _SectionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.theme, required this.data});

  final ThemeData theme;
  final _SectionCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(data.icon, color: data.color, size: 24),
              ),
              const Spacer(),
              Text(
                data.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                data.subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftTimesCard extends ConsumerWidget {
  const _ShiftTimesCard({required this.theme, required this.times});

  final ThemeData theme;
  final AppTimes times;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.alarm_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أوقات الدوام',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'الطلاب: ${times.schoolStartLabel} • الموظفون: ${times.staffStartLabel}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              tooltip: 'تعديل الأوقات',
              onPressed: () => _editTimes(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTimes(BuildContext context, WidgetRef ref) async {
    final AppTimes current = ref.read(appTimesProvider);

    final String? target = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل وقت الدخول لـ'),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, 'student'),
            child: const Text('الطلاب'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, 'staff'),
            child: const Text('الموظفون'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'both'),
            child: const Text('كلاهما'),
          ),
        ],
      ),
    );
    if (target == null || !context.mounted) return;

    TimeOfDay? school = current.schoolStart;
    TimeOfDay? staff = current.staffStart;

    if (target == 'student' || target == 'both') {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: current.schoolStart,
        helpText: 'دخول الطلاب',
      );
      if (picked == null) return;
      school = picked;
    }

    if (target == 'staff' || target == 'both') {
      if (!context.mounted) return;
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: current.staffStart,
        helpText: 'دخول الموظفين',
      );
      if (picked == null) return;
      staff = picked;
    }

    await ref.read(appTimesProvider.notifier).update(
          schoolStart: school,
          staffStart: staff,
        );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.theme, required this.today});

  final ThemeData theme;
  final AttendanceSummaryLite today;

  @override
  Widget build(BuildContext context) {
    if (today.total == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.event_busy_rounded,
                  size: 44, color: theme.hintColor),
              const SizedBox(height: 10),
              Text('لم يتم تسجيل حضور اليوم بعد',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/attendance'),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('سجل الحضور الآن'),
              ),
            ],
          ),
        ),
      );
    }

    Widget stat(String label, int value, Color color) => Expanded(
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('الطلاب',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${today.rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                stat('حاضر', today.present, const Color(0xFF16A34A)),
                stat('متأخر', today.late, const Color(0xFFF59E0B)),
                stat('غائب', today.absent, const Color(0xFFDC2626)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.theme, required this.week});

  final ThemeData theme;
  final List<DayStat> week;

  @override
  Widget build(BuildContext context) {
    final DateFormat dayFormat = DateFormat('E', 'ar');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('نسبة الحضور — آخر 7 أيام',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) =>
                          BarTooltipItem(
                        '${rod.toY.toStringAsFixed(0)}%',
                        TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dayFormat.format(week[value.toInt()].day),
                            style: TextStyle(
                                fontSize: 11, color: theme.hintColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: week.asMap().entries.map((e) {
                    final Color color = e.value.rate >= 80
                        ? const Color(0xFF16A34A)
                        : e.value.rate >= 60
                            ? const Color(0xFFF59E0B)
                            : e.value.marked == 0
                                ? theme.colorScheme.surfaceContainerHighest
                                : const Color(0xFFDC2626);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.marked == 0 ? 0 : e.value.rate,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: color,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RisksCard extends StatelessWidget {
  const _RisksCard({required this.theme, required this.risks});

  final ThemeData theme;
  final List<StudentRisk> risks;

  @override
  Widget build(BuildContext context) {
    final List<StudentRisk> risky =
        risks.where((r) => r.level != RiskLevel.low).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('طلاب يحتاجون متابعة (30 يوم)',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => context.push('/absentees'),
                  child: const Text('غائبين اليوم'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (risky.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Text('جميع الطلاب منتظمون 👏',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            else
              ...risky.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Color(r.level.colorValue).withOpacity(0.15),
                    child: Text(
                      r.studentName.isNotEmpty
                          ? r.studentName.substring(0, 1)
                          : '?',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(r.level.colorValue),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(r.studentName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'غاب ${r.absentDays} من ${r.totalDays} يوم',
                      style: TextStyle(
                          fontSize: 12, color: theme.hintColor)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(r.level.colorValue).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.level.labelAr,
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(r.level.colorValue),
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

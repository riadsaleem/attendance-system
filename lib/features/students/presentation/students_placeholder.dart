import 'package:flutter/material.dart';

import '../../../core/widgets/state_views.dart';

class StudentsPlaceholder extends StatelessWidget {
  const StudentsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyView(
        icon: Icons.school_outlined,
        title: 'باقتك الحالية لإدارة الموظفين فقط',
        subtitle: 'قسم الطلاب غير مشمول — رقّ باقتك للوصول لإدارة الطلاب',
      ),
    );
  }
}

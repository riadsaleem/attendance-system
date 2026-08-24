import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: isError ? Colors.white : null,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
}

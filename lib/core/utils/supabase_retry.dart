import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<T> supabaseRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await action();
    } on PostgrestException catch (e) {
      final bool retryable =
          e.code == 'PGRST303' || (e.code ?? '').startsWith('5');
      if (!retryable || attempt >= maxAttempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    } on SocketException {
      if (attempt >= maxAttempts) rethrow;
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    }
  }
}

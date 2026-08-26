import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';

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
      AppLog.warning(
          'retryable PostgrestException (${e.code}) — attempt $attempt');
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    } on SocketException {
      if (attempt >= maxAttempts) rethrow;
      AppLog.warning('SocketException — attempt $attempt');
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    } on TimeoutException {
      if (attempt >= maxAttempts) rethrow;
      AppLog.warning('TimeoutException — attempt $attempt');
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    } on ClientException catch (e) {
      if (attempt >= maxAttempts) rethrow;
      AppLog.warning('ClientException — attempt $attempt: ${e.message}');
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    }
  }
}

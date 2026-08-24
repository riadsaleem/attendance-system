import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/students_repository.dart';
import '../domain/models.dart';

final studentsRepositoryProvider = Provider<StudentsRepository>(
  (ref) => StudentsRepository(ref.watch(supabaseClientProvider)),
);

final classesRepositoryProvider = Provider<ClassesRepository>(
  (ref) => ClassesRepository(ref.watch(supabaseClientProvider)),
);

final studentsProvider = FutureProvider.autoDispose<List<Student>>((ref) {
  return ref.watch(studentsRepositoryProvider).fetchAll();
});

final gradesProvider = FutureProvider.autoDispose<List<Grade>>((ref) {
  return ref.watch(classesRepositoryProvider).fetchGrades();
});

final classesProvider = FutureProvider.autoDispose<List<SchoolClass>>((ref) {
  return ref.watch(classesRepositoryProvider).fetchClasses();
});

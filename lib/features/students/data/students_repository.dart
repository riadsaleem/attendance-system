import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

class StudentsRepository {
  StudentsRepository(this._client);

  final SupabaseClient _client;

  static const String _select =
      '*, classes(name, grades(name))';

  Future<List<Student>> fetchAll() async {
    final rows = await _client
        .from('students')
        .select(_select)
        .eq('is_active', true)
        .order('full_name');
    return rows.map(Student.fromJson).toList();
  }

  Future<void> insert(Student student) =>
      _client.from('students').insert(student.toDbJson());

  Future<void> update(Student student) =>
      _client.from('students').update(student.toDbJson()).eq('id', student.id);

  Future<void> delete(int id) => _client.from('students').delete().eq('id', id);
}

class ClassesRepository {
  ClassesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Grade>> fetchGrades() async {
    final rows =
        await _client.from('grades').select('id, name').order('id');
    return rows.map(Grade.fromJson).toList();
  }

  Future<List<SchoolClass>> fetchClasses() async {
    final rows = await _client
        .from('classes')
        .select('*, grades(name)')
        .order('grade_id')
        .order('name');
    return rows.map(SchoolClass.fromJson).toList();
  }

  Future<void> insertGrade(String name) =>
      _client.from('grades').insert({'name': name});

  Future<void> updateGrade(int id, String name) =>
      _client.from('grades').update({'name': name}).eq('id', id);

  Future<void> deleteGrade(int id) => _client.from('grades').delete().eq('id', id);

  Future<void> insertClass(String name, int gradeId) =>
      _client.from('classes').insert({'name': name, 'grade_id': gradeId});

  Future<void> updateClass(int id, String name, int gradeId) =>
      _client.from('classes').update({'name': name, 'grade_id': gradeId}).eq('id', id);

  Future<void> deleteClass(int id) => _client.from('classes').delete().eq('id', id);
}

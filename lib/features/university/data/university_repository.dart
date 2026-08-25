import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

class UniversityRepository {
  UniversityRepository(this._client);

  final SupabaseClient _client;

  Future<List<College>> fetchColleges() async {
    final rows =
        await _client.from('colleges').select('id, name').order('name');
    return rows.map(College.fromJson).toList();
  }

  Future<List<Major>> fetchMajors() async {
    final rows = await _client
        .from('majors')
        .select('id, name, college_id')
        .order('name');
    return rows.map(Major.fromJson).toList();
  }

  Future<void> insertCollege(String name) =>
      _client.from('colleges').insert({'name': name});

  Future<void> deleteCollege(int id) =>
      _client.from('colleges').delete().eq('id', id);

  Future<void> insertMajor(String name, int collegeId) =>
      _client.from('majors').insert({'name': name, 'college_id': collegeId});

  Future<void> deleteMajor(int id) =>
      _client.from('majors').delete().eq('id', id);
}

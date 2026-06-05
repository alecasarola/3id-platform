import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:healthcare_marketplace/core/constants/app_constants.dart';
import 'package:healthcare_marketplace/core/errors/app_exception.dart';
import 'package:healthcare_marketplace/features/nurse/domain/nurse_profile.dart';

final nurseRepositoryProvider = Provider<NurseRepository>(
  (ref) => NurseRepository(supa.Supabase.instance.client),
);

class NurseRepository {
  const NurseRepository(this._client);

  final supa.SupabaseClient _client;

  Future<NurseProfile?> fetchProfile(String nurseId) async {
    try {
      final row = await _client
          .from(AppConstants.tableNurseProfiles)
          .select()
          .eq('id', nurseId)
          .maybeSingle();
      return row != null ? NurseProfile.fromJson(row) : null;
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  Future<NurseProfile> upsertProfile(NurseProfile profile) async {
    try {
      final row = await _client
          .from(AppConstants.tableNurseProfiles)
          .upsert({'id': profile.id, ...profile.toJson()})
          .select()
          .single();
      return NurseProfile.fromJson(row);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }
}

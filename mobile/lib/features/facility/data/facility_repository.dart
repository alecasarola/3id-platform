import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:healthcare_marketplace/core/constants/app_constants.dart';
import 'package:healthcare_marketplace/core/errors/app_exception.dart';
import 'package:healthcare_marketplace/features/facility/domain/facility_profile.dart';

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(supa.Supabase.instance.client),
);

class FacilityRepository {
  const FacilityRepository(this._client);

  final supa.SupabaseClient _client;

  Future<FacilityProfile?> fetchProfile(String facilityId) async {
    try {
      final row = await _client
          .from(AppConstants.tableFacilityProfiles)
          .select()
          .eq('id', facilityId)
          .maybeSingle();
      return row != null ? FacilityProfile.fromJson(row) : null;
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  Future<FacilityProfile> upsertProfile(FacilityProfile profile) async {
    try {
      final row = await _client
          .from(AppConstants.tableFacilityProfiles)
          .upsert({'id': profile.id, ...profile.toJson()})
          .select()
          .single();
      return FacilityProfile.fromJson(row);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }
}

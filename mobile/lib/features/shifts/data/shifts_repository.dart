import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:healthcare_marketplace/core/constants/app_constants.dart';
import 'package:healthcare_marketplace/core/errors/app_exception.dart';
import 'package:healthcare_marketplace/features/shifts/domain/application.dart';
import 'package:healthcare_marketplace/features/shifts/domain/shift.dart';

final shiftsRepositoryProvider = Provider<ShiftsRepository>(
  (ref) => ShiftsRepository(supa.Supabase.instance.client),
);

class ShiftsRepository {
  const ShiftsRepository(this._client);

  final supa.SupabaseClient _client;

  // ── Shifts ────────────────────────────────────────────────────────────────

  /// Returns published shifts visible to nurses, ordered by start time.
  Future<List<Shift>> fetchPublishedShifts() async {
    try {
      final rows = await _client
          .from(AppConstants.tableShifts)
          .select()
          .eq('status', ShiftStatus.published.name)
          .order('start_at');
      return rows.map(Shift.fromJson).toList();
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Returns all shifts belonging to a facility.
  Future<List<Shift>> fetchFacilityShifts(String facilityId) async {
    try {
      final rows = await _client
          .from(AppConstants.tableShifts)
          .select()
          .eq('facility_id', facilityId)
          .order('start_at', ascending: false);
      return rows.map(Shift.fromJson).toList();
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Creates a new shift. Returns the persisted shift with server-generated id.
  Future<Shift> createShift(Shift shift) async {
    try {
      final row = await _client
          .from(AppConstants.tableShifts)
          .insert(shift.toJson())
          .select()
          .single();
      return Shift.fromJson(row);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Updates an existing shift (e.g. change status from draft to published).
  Future<Shift> updateShift(Shift shift) async {
    try {
      final row = await _client
          .from(AppConstants.tableShifts)
          .update(shift.toJson())
          .eq('id', shift.id)
          .select()
          .single();
      return Shift.fromJson(row);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  // ── Applications (candidature) ────────────────────────────────────────────

  /// Returns all applications submitted by a nurse.
  Future<List<Application>> fetchNurseApplications(String nurseId) async {
    try {
      final rows = await _client
          .from(AppConstants.tableApplications)
          .select()
          .eq('nurse_id', nurseId)
          .order('applied_at', ascending: false);
      return rows.map(Application.fromJson).toList();
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Returns all applications received for a given shift.
  Future<List<Application>> fetchShiftApplications(String shiftId) async {
    try {
      final rows = await _client
          .from(AppConstants.tableApplications)
          .select()
          .eq('shift_id', shiftId)
          .order('applied_at');
      return rows.map(Application.fromJson).toList();
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Submits a new application. Returns the persisted application.
  Future<Application> applyToShift({
    required String shiftId,
    required String nurseId,
    String? note,
  }) async {
    try {
      final row = await _client
          .from(AppConstants.tableApplications)
          .insert({
            'shift_id': shiftId,
            'nurse_id': nurseId,
            if (note != null) 'note': note,
          })
          .select()
          .single();
      return Application.fromJson(row);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  /// Withdraws an application by setting its status to 'withdrawn'.
  Future<void> withdrawApplication(String applicationId) async {
    try {
      await _client
          .from(AppConstants.tableApplications)
          .update({'status': ApplicationStatus.withdrawn.name})
          .eq('id', applicationId);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(message: e.message, code: e.code);
    }
  }

  // TODO(business): acceptApplication / rejectApplication — logica di
  // accettazione/rifiuto da implementare quando il modello di business è definito.
  // Includere qui policy RLS UPDATE per la struttura e il trigger di pagamento.
}

abstract class AppConstants {
  static const appName = 'Healthcare Marketplace';

  // Supabase table names — single source of truth to avoid typos
  static const tableProfiles = 'profiles';
  static const tableNurseProfiles = 'nurse_profiles';
  static const tableFacilityProfiles = 'facility_profiles';
  static const tableShifts = 'shifts';
  static const tableApplications = 'applications';
  static const tableClockRecords = 'clock_records'; // Step 6
}

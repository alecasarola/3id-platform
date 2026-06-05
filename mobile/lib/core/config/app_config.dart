import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class AppConfig {
  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    assert(value != null && value.isNotEmpty, 'SUPABASE_URL not set in .env');
    return value ?? '';
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    assert(value != null && value.isNotEmpty, 'SUPABASE_ANON_KEY not set in .env');
    return value ?? '';
  }
}

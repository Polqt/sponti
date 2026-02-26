import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseOptions {
  SupabaseOptions._();

  static String get supabaseUrl => dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '';
}

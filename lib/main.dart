import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sponti/config/dependency_injection.dart';
import 'package:sponti/config/routes/app_router.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file; use .env.local when available
  // flutter_dotenv throws EmptyEnvFileError if the file is missing/empty,
  // so we guard by checking for existence first.
  // Load the local env file if present, otherwise fallback to default.
  // flutter_dotenv doesn't expose a file-existence check, so we try/catch.
  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    await dotenv.load();
  }

  // Lock the orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase with the URL and anon key from environment variables
  // Supabase keys may be stored under the PUBLIC_* names in .env.local
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? dotenv.env['PUBLIC_SUPABASE_URL'];
  final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? dotenv.env['PUBLIC_SUPABASE_KEY'];

  if (supabaseUrl == null || supabaseKey == null) {
    throw Exception('Supabase environment variables not found');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize get_it depenedency injection
  await configureDependencies();

  runApp(const ProviderScope(child: SpontiApp()));
}

class SpontiApp extends StatelessWidget {
  const SpontiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sponti',
      debugShowCheckedModeBanner: false,
      theme: SpontiTheme.light,
      routerConfig: appRouter,
    );
  }
}

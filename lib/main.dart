import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:sponti/config/routes/app_router.dart';
import 'package:sponti/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables.
  // Priority: .env.local (developer override) → .env.production (release build)
  // → .env (default / debug). Pass --dart-define=FLAVOR=production to select
  // the production env at build time (e.g. flutter build apk --dart-define=FLAVOR=production).
  const flavor = String.fromEnvironment('FLAVOR');
  try {
    await dotenv.load(fileName: '.env.local');
  } catch (_) {
    try {
      if (flavor == 'production') {
        await dotenv.load(fileName: '.env.production');
      } else {
        await dotenv.load();
      }
    } catch (_) {
      await dotenv.load();
    }
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

  // Force the new Google Maps renderer on Android (no-op if already initialized)
  final mapsImpl = GoogleMapsFlutterPlatform.instance;
  if (mapsImpl is GoogleMapsFlutterAndroid) {
    mapsImpl.useAndroidViewSurface = true;
    try {
      await mapsImpl.initializeWithRenderer(AndroidMapRenderer.latest);
    } catch (_) {
      // Already initialized (e.g. hot restart) — safe to ignore
    }
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

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

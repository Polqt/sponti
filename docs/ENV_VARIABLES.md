# Environment Variables: Sponti

**Purpose**: All secrets, API keys, and configuration needed for this project
**Date**: 2026-03-08

---

## Development (.env.local)

**File**: `.env.local` (local file, NOT committed to git — already in .gitignore)

```bash
# Supabase
PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
PUBLIC_SUPABASE_KEY=eyJhbG...your-anon-key...

# Alternative names (app checks both)
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_KEY=eyJhbG...your-anon-key...

# Google OAuth
GOOGLE_SERVER_CLIENT_ID=your-google-server-client-id.apps.googleusercontent.com

# Facebook OAuth (configured in AndroidManifest.xml / Info.plist, not env)
# FACEBOOK_APP_ID=your-facebook-app-id
```

**How to get these keys:**
1. **Supabase URL + Anon Key**: https://supabase.com/dashboard → Your Project → Settings → API → Project URL + `anon public` key
2. **Google Server Client ID**: https://console.cloud.google.com → APIs & Services → Credentials → OAuth 2.0 Client IDs → Web application client ID (used for `serverClientId`)
3. **Facebook App ID**: https://developers.facebook.com → Your App → Settings → Basic → App ID (configured in native manifests, not .env)

---

## File Locations

| Variable | File | Notes |
|----------|------|-------|
| `PUBLIC_SUPABASE_URL` / `SUPABASE_URL` | `.env.local` | Loaded via `flutter_dotenv` |
| `PUBLIC_SUPABASE_KEY` / `SUPABASE_KEY` | `.env.local` | Supabase anon key (safe for client) |
| `GOOGLE_SERVER_CLIENT_ID` | `.env.local` | Google OAuth server client ID |
| Facebook App ID | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | Native config |
| Google Services | `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` | Firebase/Google config |

---

## Environment Variable Reference

| Variable | Required | Where Used | Notes |
|----------|----------|------------|-------|
| PUBLIC_SUPABASE_URL | Yes | `main.dart` → Supabase.initialize | Project URL |
| PUBLIC_SUPABASE_KEY | Yes | `main.dart` → Supabase.initialize | Anon public key (safe for client) |
| GOOGLE_SERVER_CLIENT_ID | Yes | `auth_remote_datasource.dart` | For Google Sign-In token exchange |

---

## Setup Checklist

### Local Development
- [ ] Create `.env.local` in project root (copy template above)
- [ ] Verify `.env.local` is in `.gitignore`
- [ ] Get Supabase URL + anon key from Supabase dashboard
- [ ] Get Google server client ID from Google Cloud Console
- [ ] Configure Facebook App ID in AndroidManifest.xml
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` to verify

### Production / Release Build
- [ ] Use separate Supabase project for production
- [ ] Use production Google OAuth client IDs
- [ ] Use production Facebook App credentials
- [ ] Ensure `.env.local` has production values OR use build-time env injection

---

## Security Notes

**Never commit:**
- `.env.local` (contains Supabase keys)
- `google-services.json` (if contains sensitive data)
- Any file with actual secret values

**Safe to commit:**
- `.env` (if it only contains placeholder/example values)
- `pubspec.yaml` (no secrets)

**Supabase Anon Key:**
The anon key is designed to be public (used client-side). Security is enforced via Row Level Security (RLS) policies on the database, not by hiding the key. Never use the `service_role` key in the Flutter app.

**If API keys are leaked:**
1. Rotate Supabase API keys in dashboard → Settings → API
2. Generate new Google OAuth client IDs
3. Regenerate Facebook app secret
4. Update `.env.local` with new values

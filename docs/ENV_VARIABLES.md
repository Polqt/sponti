# Environment Variables: Sponti

**Purpose**: All secrets, API keys, and configuration needed for this project
**Date**: 2026-03-12

---

## Development (.env.local)

**File**: `.env.local` (local file, NOT committed to git - already in .gitignore)

```bash
# Supabase
PUBLIC_SUPABASE_URL=https://your-project-ref.supabase.co
PUBLIC_SUPABASE_KEY=eyJhbG...your-anon-key...

# Alternative names (app checks both)
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_KEY=eyJhbG...your-anon-key...
```

**How to get these keys:**
1. **Supabase URL + Anon Key**: https://supabase.com/dashboard -> Your Project -> Settings -> API -> Project URL + `anon public` key

---

## File Locations

| Variable | File | Notes |
|----------|------|-------|
| `PUBLIC_SUPABASE_URL` / `SUPABASE_URL` | `.env.local` | Loaded via `flutter_dotenv` |
| `PUBLIC_SUPABASE_KEY` / `SUPABASE_KEY` | `.env.local` | Supabase anon key (safe for client) |
| OAuth redirect scheme | `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist` | Must match `io.supabase.sponti://login-callback/` |

---

## Environment Variable Reference

| Variable | Required | Where Used | Notes |
|----------|----------|------------|-------|
| PUBLIC_SUPABASE_URL | Yes | `main.dart` -> Supabase.initialize | Project URL |
| PUBLIC_SUPABASE_KEY | Yes | `main.dart` -> Supabase.initialize | Anon public key (safe for client) |

---

## Setup Checklist

### Local Development
- [ ] Create `.env.local` in project root (copy template above)
- [ ] Verify `.env.local` is in `.gitignore`
- [ ] Get Supabase URL + anon key from Supabase dashboard
- [ ] Run `flutter pub get`
- [ ] Run `flutter run` to verify

### Production / Release Build
- [ ] Use a separate Supabase project for production
- [ ] Configure Google/Facebook OAuth providers in Supabase dashboard
- [ ] Ensure redirect URL list includes `io.supabase.sponti://login-callback/`
- [ ] Ensure `.env.local` has production values or use build-time env injection

---

## Security Notes

**Never commit:**
- `.env.local` (contains Supabase keys)
- Any file with actual secret values

**Safe to commit:**
- `.env` (if it only contains placeholder/example values)
- `pubspec.yaml` (no secrets)

**Supabase Anon Key:**
The anon key is designed to be public (used client-side). Security is enforced via Row Level Security (RLS) policies on the database, not by hiding the key. Never use the `service_role` key in the Flutter app.

**If API keys are leaked:**
1. Rotate Supabase API keys in dashboard -> Settings -> API
2. Rotate OAuth provider secrets in Supabase Authentication settings
3. Update `.env.local` with new values

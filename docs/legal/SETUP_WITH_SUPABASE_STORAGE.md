# Setup Legal URLs With Supabase Storage

Use this if you do not have your own domain yet.

## 1) Create bucket
- Supabase Dashboard -> Storage -> New bucket
- Name: `legal`
- Public bucket: enabled

## 2) Upload files
Upload these files from this repo:
- `docs/legal/index.html`
- `docs/legal/privacy.html`
- `docs/legal/terms.html`
- `docs/legal/delete-account.html`

## 3) Public URLs
Use these URLs in Google and Meta:
- Home page: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/storage/v1/object/public/legal/index.html`
- Privacy policy: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/storage/v1/object/public/legal/privacy.html`
- Terms: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/storage/v1/object/public/legal/terms.html`
- Data deletion: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/storage/v1/object/public/legal/delete-account.html`

## 4) Google Branding fields
- Application home page: home page URL above
- Application privacy policy link: privacy policy URL above
- Application terms of service link: terms URL above
- Authorized domain: `iqdzzhcetrxxqkrmnhzo.supabase.co`

## 5) Google OAuth client (Web)
- Authorized redirect URI: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/auth/v1/callback`

## 6) Meta Basic fields
- App domains: `iqdzzhcetrxxqkrmnhzo.supabase.co`
- Privacy policy URL: privacy policy URL above
- Terms of Service URL: terms URL above
- User data deletion: choose `Data deletion instructions URL` and use data deletion URL above

## 7) Meta Facebook Login settings
- Valid OAuth Redirect URIs: `https://iqdzzhcetrxxqkrmnhzo.supabase.co/auth/v1/callback`

## 8) Friend login access
- Google in testing mode: add friend email in Google Auth Platform -> Audience -> Test users
- Meta app unpublished: add friend as Tester in App roles and they must accept invite

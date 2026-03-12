-- Migration: Backfill missing profiles for existing auth users
-- This repairs accounts created before the trigger existed or when it failed.

INSERT INTO public.profiles (id, full_name, avatar_url, bio)
SELECT
  u.id,
  COALESCE(
    NULLIF(u.raw_user_meta_data ->> 'full_name', ''),
    NULLIF(u.raw_user_meta_data ->> 'name', ''),
    ''
  ),
  COALESCE(
    NULLIF(u.raw_user_meta_data ->> 'avatar_url', ''),
    NULLIF(u.raw_user_meta_data ->> 'picture', ''),
    ''
  ),
  ''
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

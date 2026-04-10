-- Migration: get_friend_activity RPC
-- Returns the most recent check-ins from the caller's friends,
-- enriched with location name/photo and friend's profile info.
-- Used by the Discovery "Friends" feed.

CREATE OR REPLACE FUNCTION public.get_friend_activity(
  p_limit  INTEGER DEFAULT 30,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  check_in_id      UUID,
  checked_in_at    TIMESTAMPTZ,
  note             TEXT,
  photos           JSONB,
  location_id      UUID,
  location_name    TEXT,
  location_address TEXT,
  location_category TEXT,
  location_photo   TEXT,
  friend_id        UUID,
  friend_username  TEXT,
  friend_full_name TEXT,
  friend_avatar    TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    ci.id                                        AS check_in_id,
    ci.created_at                                AS checked_in_at,
    ci.note,
    ci.photos,
    l.id                                         AS location_id,
    l.name                                       AS location_name,
    l.address                                    AS location_address,
    l.category                                   AS location_category,
    (l.photos ->> 0)                             AS location_photo,
    p.id                                         AS friend_id,
    p.username                                   AS friend_username,
    p.full_name                                  AS friend_full_name,
    p.avatar_url                                 AS friend_avatar
  FROM public.friend_connections fc
  JOIN public.check_ins ci     ON ci.user_id     = fc.friend_id
  JOIN public.locations  l     ON l.id           = ci.location_id
  JOIN public.profiles   p     ON p.id           = fc.friend_id
  WHERE fc.user_id = auth.uid()
  ORDER BY ci.created_at DESC
  LIMIT  GREATEST(p_limit,  1)
  OFFSET GREATEST(p_offset, 0);
$$;

GRANT EXECUTE ON FUNCTION public.get_friend_activity(INTEGER, INTEGER)
  TO authenticated;

-- ── search_users RPC ──────────────────────────────────────────────────────────
-- Searches profiles by username or full_name.
-- Used by the "Add Friends" search in FriendsScreen.

CREATE OR REPLACE FUNCTION public.search_users(
  query        TEXT,
  p_limit      INTEGER DEFAULT 20,
  p_offset     INTEGER DEFAULT 0
)
RETURNS SETOF public.profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT *
  FROM public.profiles
  WHERE
    id <> auth.uid()
    AND (
      username  ILIKE '%' || TRIM(query) || '%'
      OR full_name ILIKE '%' || TRIM(query) || '%'
    )
  ORDER BY
    CASE WHEN username ILIKE TRIM(query) || '%' THEN 0 ELSE 1 END,
    full_name
  LIMIT  GREATEST(p_limit,  1)
  OFFSET GREATEST(p_offset, 0);
$$;

GRANT EXECUTE ON FUNCTION public.search_users(TEXT, INTEGER, INTEGER)
  TO authenticated;

-- Migration: simplify curator ranking to use the existing profile counters.
-- The base review/check-in triggers already maintain profiles.total_reviews and
-- profiles.total_check_ins, so no extra profile activity trigger is needed.

DROP TRIGGER IF EXISTS on_profile_activity_change ON public.profiles;
DROP FUNCTION IF EXISTS public.touch_profile_activity_timestamp();

DROP INDEX IF EXISTS idx_profiles_curator_rank;

CREATE INDEX IF NOT EXISTS idx_profiles_curator_rank
  ON public.profiles (
    (COALESCE(total_reviews, 0) + COALESCE(total_check_ins, 0)) DESC,
    total_reviews DESC,
    total_check_ins DESC,
    lower(COALESCE(NULLIF(BTRIM(full_name), ''), NULLIF(BTRIM(username), ''), '')) ASC,
    id ASC
  );

CREATE OR REPLACE FUNCTION public.get_top_curators(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
  profile_id UUID,
  full_name TEXT,
  username TEXT,
  avatar_url TEXT,
  total_reviews INTEGER,
  total_check_ins INTEGER,
  activity_score INTEGER,
  curator_rank BIGINT,
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH ranked_curators AS (
    SELECT
      p.id AS profile_id,
      p.full_name,
      p.username,
      p.avatar_url,
      p.total_reviews,
      p.total_check_ins,
      COALESCE(p.total_reviews, 0) + COALESCE(p.total_check_ins, 0)
        AS activity_score,
      p.updated_at,
      DENSE_RANK() OVER (
        ORDER BY
          (COALESCE(p.total_reviews, 0) + COALESCE(p.total_check_ins, 0)) DESC,
          p.total_reviews DESC,
          p.total_check_ins DESC,
          lower(
            COALESCE(
              NULLIF(BTRIM(p.full_name), ''),
              NULLIF(BTRIM(p.username), ''),
              ''
            )
          ) ASC,
          p.id ASC
      ) AS curator_rank
    FROM public.profiles p
    WHERE COALESCE(p.total_reviews, 0) + COALESCE(p.total_check_ins, 0) > 0
  )
  SELECT
    profile_id,
    full_name,
    username,
    avatar_url,
    total_reviews,
    total_check_ins,
    activity_score,
    curator_rank,
    updated_at
  FROM ranked_curators
  ORDER BY
    curator_rank ASC,
    lower(
      COALESCE(
        NULLIF(BTRIM(full_name), ''),
        NULLIF(BTRIM(username), ''),
        ''
      )
    ) ASC,
    profile_id ASC
  LIMIT GREATEST(limit_count, 1);
$$;

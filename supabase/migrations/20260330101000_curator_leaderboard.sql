-- Migration: profile-backed top curators for Discovery.
-- Uses the existing profile counters directly instead of duplicating curator
-- rows into a separate table.

DROP TRIGGER IF EXISTS on_profile_curator_leaderboard_change ON public.profiles;
DROP FUNCTION IF EXISTS public.sync_curator_leaderboard();
DROP FUNCTION IF EXISTS public.rebuild_curator_leaderboard_row(UUID);
DROP TABLE IF EXISTS public.curator_leaderboard;

CREATE INDEX IF NOT EXISTS idx_profiles_curator_rank
  ON public.profiles (
    (COALESCE(total_reviews, 0) + COALESCE(total_check_ins, 0)) DESC,
    total_reviews DESC,
    total_check_ins DESC,
    updated_at DESC
  );

CREATE OR REPLACE FUNCTION public.touch_profile_activity_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_profile_activity_change ON public.profiles;

CREATE TRIGGER on_profile_activity_change
BEFORE UPDATE OF total_reviews, total_check_ins ON public.profiles
FOR EACH ROW
WHEN (
  OLD.total_reviews IS DISTINCT FROM NEW.total_reviews
  OR OLD.total_check_ins IS DISTINCT FROM NEW.total_check_ins
)
EXECUTE FUNCTION public.touch_profile_activity_timestamp();

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
          p.updated_at DESC
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
    updated_at DESC
  LIMIT GREATEST(limit_count, 1);
$$;

GRANT EXECUTE ON FUNCTION public.touch_profile_activity_timestamp() TO authenticated;
GRANT EXECUTE ON FUNCTION public.touch_profile_activity_timestamp() TO anon;
GRANT EXECUTE ON FUNCTION public.get_top_curators(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_curators(INTEGER) TO anon;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
  END;
END $$;

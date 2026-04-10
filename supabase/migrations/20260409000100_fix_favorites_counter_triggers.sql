-- Migration: fix duplicate favorites counter triggers and backfill totals.
--
-- Why:
-- Hosted environments may contain both legacy and newer favorites triggers,
-- causing total_favorites to increment/decrement twice and drift (including negatives).

-- Keep one canonical trigger function.
CREATE OR REPLACE FUNCTION public.update_profile_favorites_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.profiles
    SET total_favorites = COALESCE(total_favorites, 0) + 1,
        updated_at = now()
    WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.profiles
    SET total_favorites = GREATEST(COALESCE(total_favorites, 0) - 1, 0),
        updated_at = now()
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

-- Remove duplicate/legacy triggers if they exist.
DROP TRIGGER IF EXISTS on_favorite_insert ON public.favorites;
DROP TRIGGER IF EXISTS on_favorite_delete ON public.favorites;
DROP TRIGGER IF EXISTS on_favorite_change ON public.favorites;

-- Keep a single trigger that handles both insert/delete.
CREATE TRIGGER on_favorite_change
AFTER INSERT OR DELETE ON public.favorites
FOR EACH ROW
EXECUTE FUNCTION public.update_profile_favorites_count();

-- Remove legacy functions used by old triggers.
DROP FUNCTION IF EXISTS public.increment_user_favorites_count();
DROP FUNCTION IF EXISTS public.decrement_user_favorites_count();

-- Backfill denormalized totals to match current favorites rows.
WITH favorites_count AS (
  SELECT user_id, COUNT(*)::INTEGER AS cnt
  FROM public.favorites
  GROUP BY user_id
), recomputed AS (
  SELECT p.id, COALESCE(fc.cnt, 0) AS cnt
  FROM public.profiles p
  LEFT JOIN favorites_count fc ON fc.user_id = p.id
)
UPDATE public.profiles p
SET total_favorites = r.cnt,
    updated_at = now()
FROM recomputed r
WHERE p.id = r.id
  AND p.total_favorites IS DISTINCT FROM r.cnt;

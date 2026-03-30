-- Migration: repair profile favorite counters for local and remote parity.
-- The app already reads profiles.total_favorites, but the historical migration
-- file was left empty. This adds the column, backfills existing data, and keeps
-- it in sync going forward.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_favorites INTEGER NOT NULL DEFAULT 0;

UPDATE public.profiles p
SET total_favorites = COALESCE(f.favorite_count, 0)
FROM (
  SELECT
    user_id,
    COUNT(*)::INTEGER AS favorite_count
  FROM public.favorites
  GROUP BY user_id
) AS f
WHERE p.id = f.user_id;

UPDATE public.profiles
SET total_favorites = 0
WHERE id NOT IN (
  SELECT DISTINCT user_id
  FROM public.favorites
);

CREATE OR REPLACE FUNCTION public.update_profile_favorites_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.profiles
    SET total_favorites = total_favorites + 1
    WHERE id = NEW.user_id;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    UPDATE public.profiles
    SET total_favorites = GREATEST(total_favorites - 1, 0)
    WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_favorite_change ON public.favorites;

CREATE TRIGGER on_favorite_change
AFTER INSERT OR DELETE ON public.favorites
FOR EACH ROW
EXECUTE FUNCTION public.update_profile_favorites_count();

GRANT EXECUTE ON FUNCTION public.update_profile_favorites_count() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_profile_favorites_count() TO anon;

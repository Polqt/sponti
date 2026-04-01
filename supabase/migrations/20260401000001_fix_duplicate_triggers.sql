-- Migration: Fix double-counting on check-ins and favorites.
--
-- Root cause 1 (check-ins):
--   20260308000006_triggers.sql used CREATE TRIGGER (not idempotent).
--   If the migration was applied on a DB that already had the trigger
--   (e.g. after a schema re-import), Postgres registered two triggers
--   both named on_checkin_change, causing every INSERT to fire twice
--   and increment check_in_count / total_check_ins by 2.
--
-- Root cause 2 (favorites):
--   Same idempotency problem for on_review_change.
--   Additionally the app's addFavorite used upsert without
--   ignoreDuplicates, so re-saving an existing favorite could fire
--   on_favorite_change a second time via the UPDATE path.
--
-- Fix: drop then recreate all three triggers idempotently so exactly
--      one trigger exists for each event.

-- ── Check-in count trigger ────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS on_checkin_change    ON public.check_ins;
DROP TRIGGER IF EXISTS trg_check_in_count   ON public.check_ins;   -- legacy name

CREATE OR REPLACE FUNCTION public.update_checkin_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations
      SET check_in_count = check_in_count + 1
      WHERE id = NEW.location_id;
    UPDATE public.profiles
      SET total_check_ins = total_check_ins + 1
      WHERE id = NEW.user_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations
      SET check_in_count = GREATEST(check_in_count - 1, 0)
      WHERE id = OLD.location_id;
    UPDATE public.profiles
      SET total_check_ins = GREATEST(total_check_ins - 1, 0)
      WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER on_checkin_change
  AFTER INSERT OR DELETE ON public.check_ins
  FOR EACH ROW
  EXECUTE FUNCTION public.update_checkin_count();

-- ── Review rating trigger ─────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS on_review_change ON public.reviews;

CREATE OR REPLACE FUNCTION public.update_location_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations SET
      rating       = (SELECT COALESCE(AVG(r.rating), 0)   FROM public.reviews r WHERE r.location_id = NEW.location_id),
      review_count = (SELECT COUNT(*)::integer             FROM public.reviews r WHERE r.location_id = NEW.location_id)
    WHERE id = NEW.location_id;
    UPDATE public.profiles SET total_reviews = total_reviews + 1 WHERE id = NEW.user_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations SET
      rating       = (SELECT COALESCE(AVG(r.rating), 0)   FROM public.reviews r WHERE r.location_id = OLD.location_id),
      review_count = (SELECT COUNT(*)::integer             FROM public.reviews r WHERE r.location_id = OLD.location_id)
    WHERE id = OLD.location_id;
    UPDATE public.profiles SET total_reviews = GREATEST(total_reviews - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.locations SET
      rating = (SELECT COALESCE(AVG(r.rating), 0) FROM public.reviews r WHERE r.location_id = NEW.location_id)
    WHERE id = NEW.location_id;
    RETURN NEW;
  END IF;
END;
$$;

CREATE TRIGGER on_review_change
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_location_rating();

-- ── Favorites counter trigger ─────────────────────────────────────────────────

DROP TRIGGER IF EXISTS on_favorite_change ON public.favorites;

CREATE OR REPLACE FUNCTION public.update_profile_favorites_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.profiles SET total_favorites = total_favorites + 1 WHERE id = NEW.user_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.profiles SET total_favorites = GREATEST(total_favorites - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER on_favorite_change
  AFTER INSERT OR DELETE ON public.favorites
  FOR EACH ROW
  EXECUTE FUNCTION public.update_profile_favorites_count();

-- ── Backfill counters to correct any inflated values ─────────────────────────

UPDATE public.locations l
SET check_in_count = (SELECT COUNT(*) FROM public.check_ins c WHERE c.location_id = l.id);

UPDATE public.locations l
SET
  rating       = COALESCE((SELECT AVG(r.rating)   FROM public.reviews r WHERE r.location_id = l.id), 0),
  review_count = COALESCE((SELECT COUNT(*)         FROM public.reviews r WHERE r.location_id = l.id), 0);

UPDATE public.profiles p
SET total_check_ins = COALESCE((SELECT COUNT(*) FROM public.check_ins c   WHERE c.user_id = p.id), 0);

UPDATE public.profiles p
SET total_reviews   = COALESCE((SELECT COUNT(*) FROM public.reviews r     WHERE r.user_id = p.id), 0);

UPDATE public.profiles p
SET total_favorites = COALESCE((SELECT COUNT(*) FROM public.favorites f   WHERE f.user_id = p.id), 0);

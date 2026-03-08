-- Migration: Triggers for auto-updating rating/review_count/check_in_count
-- These keep locations.rating, locations.review_count, locations.check_in_count,
-- and profiles.total_reviews, profiles.total_check_ins in sync automatically.

-- REVIEW RATING TRIGGER
CREATE OR REPLACE FUNCTION update_location_rating()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations SET
      rating = (SELECT COALESCE(AVG(r.rating), 0) FROM public.reviews r WHERE r.location_id = NEW.location_id),
      review_count = (SELECT COUNT(*)::integer FROM public.reviews r WHERE r.location_id = NEW.location_id)
    WHERE id = NEW.location_id;

    UPDATE public.profiles SET total_reviews = total_reviews + 1 WHERE id = NEW.user_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations SET
      rating = (SELECT COALESCE(AVG(r.rating), 0) FROM public.reviews r WHERE r.location_id = OLD.location_id),
      review_count = (SELECT COUNT(*)::integer FROM public.reviews r WHERE r.location_id = OLD.location_id)
    WHERE id = OLD.location_id;

    UPDATE public.profiles SET total_reviews = GREATEST(total_reviews - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;

  ELSIF TG_OP = 'UPDATE' THEN
    -- User edited their review rating
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
  EXECUTE FUNCTION update_location_rating();

-- CHECK-IN COUNT TRIGGER
CREATE OR REPLACE FUNCTION update_checkin_count()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations SET check_in_count = check_in_count + 1 WHERE id = NEW.location_id;
    UPDATE public.profiles SET total_check_ins = total_check_ins + 1 WHERE id = NEW.user_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations SET check_in_count = GREATEST(check_in_count - 1, 0) WHERE id = OLD.location_id;
    UPDATE public.profiles SET total_check_ins = GREATEST(total_check_ins - 1, 0) WHERE id = OLD.user_id;
    RETURN OLD;
  END IF;
END;
$$;

CREATE TRIGGER on_checkin_change
  AFTER INSERT OR DELETE ON public.check_ins
  FOR EACH ROW
  EXECUTE FUNCTION update_checkin_count();

-- Migration: Persist check-in streak metrics on profiles and keep them updated.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS current_checkin_streak INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS longest_checkin_streak INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_check_in_date DATE,
  ADD COLUMN IF NOT EXISTS streak_updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

-- Deterministic streak computation from public.check_ins for a single user.
CREATE OR REPLACE FUNCTION public.compute_user_checkin_streak(p_user_id UUID)
RETURNS TABLE (
  current_streak_days INTEGER,
  longest_streak_days INTEGER,
  last_check_in_date DATE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH unique_days AS (
    SELECT DISTINCT (c.created_at AT TIME ZONE 'UTC')::date AS checkin_day
    FROM public.check_ins c
    WHERE c.user_id = p_user_id
  ),
  ordered_days AS (
    SELECT
      checkin_day,
      LEAD(checkin_day) OVER (ORDER BY checkin_day DESC) AS next_older_day
    FROM unique_days
  ),
  segmented AS (
    SELECT
      checkin_day,
      SUM(
        CASE
          WHEN next_older_day = checkin_day - 1 THEN 0
          ELSE 1
        END
      ) OVER (ORDER BY checkin_day DESC) AS segment_id
    FROM ordered_days
  ),
  streak_lengths AS (
    SELECT
      segment_id,
      MAX(checkin_day) AS newest_day,
      COUNT(*)::integer AS streak_days
    FROM segmented
    GROUP BY segment_id
  ),
  latest_day AS (
    SELECT MAX(checkin_day) AS day
    FROM unique_days
  )
  SELECT
    COALESCE(
      (
        SELECT
          CASE
            WHEN ld.day IS NULL THEN 0
            WHEN CURRENT_DATE - ld.day > 1 THEN 0
            ELSE sl.streak_days
          END
        FROM latest_day ld
        LEFT JOIN streak_lengths sl ON sl.newest_day = ld.day
      ),
      0
    )::integer AS current_streak_days,
    COALESCE((SELECT MAX(streak_days) FROM streak_lengths), 0)::integer
      AS longest_streak_days,
    (SELECT day FROM latest_day) AS last_check_in_date;
$$;

CREATE OR REPLACE FUNCTION public.refresh_user_checkin_streak(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_current INTEGER := 0;
  v_longest INTEGER := 0;
  v_last DATE := NULL;
BEGIN
  SELECT
    s.current_streak_days,
    s.longest_streak_days,
    s.last_check_in_date
  INTO
    v_current,
    v_longest,
    v_last
  FROM public.compute_user_checkin_streak(p_user_id) s;

  UPDATE public.profiles
  SET
    current_checkin_streak = COALESCE(v_current, 0),
    longest_checkin_streak = COALESCE(v_longest, 0),
    last_check_in_date = v_last,
    streak_updated_at = now()
  WHERE id = p_user_id;
END;
$$;

-- Keep check-in count and streak metrics in sync from the same trigger.
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

    PERFORM public.refresh_user_checkin_streak(NEW.user_id);
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations
      SET check_in_count = GREATEST(check_in_count - 1, 0)
      WHERE id = OLD.location_id;
    UPDATE public.profiles
      SET total_check_ins = GREATEST(total_check_ins - 1, 0)
      WHERE id = OLD.user_id;

    PERFORM public.refresh_user_checkin_streak(OLD.user_id);
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_checkin_change ON public.check_ins;
CREATE TRIGGER on_checkin_change
  AFTER INSERT OR DELETE ON public.check_ins
  FOR EACH ROW
  EXECUTE FUNCTION public.update_checkin_count();

-- Public RPC for client reads (server-authoritative values).
CREATE OR REPLACE FUNCTION public.get_user_checkin_streak(target_user_id UUID)
RETURNS TABLE (
  current_streak_days INTEGER,
  longest_streak_days INTEGER,
  last_check_in_date DATE
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    COALESCE(p.current_checkin_streak, 0)::INTEGER AS current_streak_days,
    COALESCE(p.longest_checkin_streak, 0)::INTEGER AS longest_streak_days,
    p.last_check_in_date
  FROM public.profiles p
  WHERE p.id = target_user_id
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.compute_user_checkin_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_user_checkin_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_checkin_streak(UUID) TO authenticated;

-- Backfill profile counters and streak columns.
UPDATE public.profiles p
SET total_check_ins = COALESCE((
  SELECT COUNT(*)
  FROM public.check_ins c
  WHERE c.user_id = p.id
), 0);

SELECT public.refresh_user_checkin_streak(p.id)
FROM public.profiles p;

-- Migration: Add check-in streak RPC helpers.
-- Uses existing public.check_ins table; no new table required.

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
  WITH unique_days AS (
    SELECT DISTINCT (c.created_at AT TIME ZONE 'UTC')::date AS checkin_day
    FROM public.check_ins c
    WHERE c.user_id = target_user_id
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

GRANT EXECUTE ON FUNCTION public.get_user_checkin_streak(UUID) TO authenticated;

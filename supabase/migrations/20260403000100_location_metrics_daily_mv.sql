-- Migration: derived daily metrics for scalable ranking and live signals.
-- This is additive and safe to deploy before the app switches to the new
-- search/ranking pipeline.

DROP MATERIALIZED VIEW IF EXISTS public.location_metrics_daily;

CREATE MATERIALIZED VIEW public.location_metrics_daily AS
WITH activity_dates AS (
  SELECT
    c.location_id,
    (c.created_at AT TIME ZONE 'UTC')::date AS metric_date
  FROM public.check_ins c
  UNION
  SELECT
    r.location_id,
    (r.created_at AT TIME ZONE 'UTC')::date AS metric_date
  FROM public.reviews r
  UNION
  SELECT
    f.location_id,
    (f.created_at AT TIME ZONE 'UTC')::date AS metric_date
  FROM public.favorites f
),
daily_checkins AS (
  SELECT
    c.location_id,
    (c.created_at AT TIME ZONE 'UTC')::date AS metric_date,
    COUNT(*)::integer AS check_in_count
  FROM public.check_ins c
  GROUP BY c.location_id, (c.created_at AT TIME ZONE 'UTC')::date
),
daily_reviews AS (
  SELECT
    r.location_id,
    (r.created_at AT TIME ZONE 'UTC')::date AS metric_date,
    COUNT(*)::integer AS review_count
  FROM public.reviews r
  GROUP BY r.location_id, (r.created_at AT TIME ZONE 'UTC')::date
),
daily_favorites AS (
  SELECT
    f.location_id,
    (f.created_at AT TIME ZONE 'UTC')::date AS metric_date,
    COUNT(*)::integer AS favorite_count
  FROM public.favorites f
  GROUP BY f.location_id, (f.created_at AT TIME ZONE 'UTC')::date
)
SELECT
  a.location_id,
  a.metric_date,
  COALESCE(dc.check_in_count, 0)::integer AS check_in_count,
  COALESCE(dr.review_count, 0)::integer AS review_count,
  COALESCE(df.favorite_count, 0)::integer AS favorite_count,
  now() AS generated_at
FROM activity_dates a
LEFT JOIN daily_checkins dc
  ON dc.location_id = a.location_id
 AND dc.metric_date = a.metric_date
LEFT JOIN daily_reviews dr
  ON dr.location_id = a.location_id
 AND dr.metric_date = a.metric_date
LEFT JOIN daily_favorites df
  ON df.location_id = a.location_id
 AND df.metric_date = a.metric_date;

CREATE UNIQUE INDEX idx_location_metrics_daily_pk
  ON public.location_metrics_daily(location_id, metric_date);

CREATE INDEX idx_location_metrics_daily_date
  ON public.location_metrics_daily(metric_date DESC);

CREATE OR REPLACE FUNCTION public.refresh_location_metrics_daily()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW public.location_metrics_daily;
END;
$$;

GRANT SELECT ON public.location_metrics_daily TO authenticated;
GRANT SELECT ON public.location_metrics_daily TO anon;
GRANT EXECUTE ON FUNCTION public.refresh_location_metrics_daily() TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_location_metrics_daily() TO anon;

SELECT public.refresh_location_metrics_daily();

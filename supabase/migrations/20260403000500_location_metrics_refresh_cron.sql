-- Schedule periodic, non-blocking refreshes for location_metrics_daily.
-- NOTE: REFRESH MATERIALIZED VIEW CONCURRENTLY cannot run inside a SQL function
-- transaction block, so we schedule it directly with pg_cron.

CREATE EXTENSION IF NOT EXISTS pg_cron;

DO $$
DECLARE
  existing_job_id bigint;
BEGIN
  BEGIN
    SELECT jobid
      INTO existing_job_id
      FROM cron.job
     WHERE jobname = 'refresh-location-metrics-daily'
     LIMIT 1;
  EXCEPTION
    WHEN undefined_table THEN
      existing_job_id := NULL;
  END;

  IF existing_job_id IS NOT NULL THEN
    PERFORM cron.unschedule(existing_job_id);
  END IF;
END
$$;

SELECT cron.schedule(
  'refresh-location-metrics-daily',
  '*/15 * * * *',
  'REFRESH MATERIALIZED VIEW CONCURRENTLY public.location_metrics_daily;'
);


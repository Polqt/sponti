-- SQL contract tests for search_locations_ranked and location_metrics_daily.
-- Run with: supabase test db
-- Uses pgTAP (bundled with Supabase local dev).

BEGIN;

SELECT plan(17);

-- ── 1. location_metrics_daily view exists ────────────────────────────────────

SELECT has_view(
  'public',
  'location_metrics_daily',
  'location_metrics_daily materialized view exists'
);

-- ── 2. Required columns are present ──────────────────────────────────────────

SELECT has_column('public', 'location_metrics_daily', 'location_id',     'has location_id');
SELECT has_column('public', 'location_metrics_daily', 'metric_date',     'has metric_date');
SELECT has_column('public', 'location_metrics_daily', 'check_in_count',  'has check_in_count');
SELECT has_column('public', 'location_metrics_daily', 'review_count',    'has review_count');
SELECT has_column('public', 'location_metrics_daily', 'favorite_count',  'has favorite_count');
SELECT has_column('public', 'location_metrics_daily', 'generated_at',    'has generated_at');

-- ── 3. refresh_location_metrics_daily function exists ────────────────────────

SELECT has_function(
  'public',
  'refresh_location_metrics_daily',
  ARRAY[]::TEXT[],
  'refresh_location_metrics_daily() function exists'
);

-- ── 4. search_locations_ranked function exists ───────────────────────────────

SELECT has_function(
  'public',
  'search_locations_ranked',
  ARRAY['text', 'double precision', 'double precision', 'integer'],
  'search_locations_ranked(text, float8, float8, int) function exists'
);

-- ── 5. search_locations_ranked returns expected columns ──────────────────────
-- Call with an empty result set (nonsense query) to validate the return shape.

DO $$
DECLARE
  r record;
BEGIN
  SELECT * INTO r
  FROM public.search_locations_ranked('__no_match_xyzzy__', NULL, NULL, 1)
  LIMIT 1;
  -- If the RPC signature changed this block would error, caught by pgTAP harness.
END;
$$;

SELECT pass('search_locations_ranked signature is callable');

-- ── 6. Ranked results respect limit_count ────────────────────────────────────

SELECT ok(
  (
    SELECT COUNT(*) <= 3
    FROM public.search_locations_ranked(
      (SELECT COALESCE(MIN(name), 'cafe') FROM public.locations LIMIT 1),
      NULL, NULL, 3
    )
  ),
  'ranked search respects limit_count=3'
);

-- ── 7. get_trending_locations 8-arg overload no longer exists (replaced by 9-arg) ─

SELECT hasnt_function(
  'public',
  'get_trending_locations',
  ARRAY['text', 'text', 'text', 'boolean', 'boolean', 'boolean', 'boolean', 'integer'],
  'old 8-arg get_trending_locations overload has been replaced'
);

-- ── 8. get_trending_locations 9-arg overload exists ──────────────────────────

SELECT has_function(
  'public',
  'get_trending_locations',
  ARRAY['text', 'text', 'text', 'boolean', 'boolean', 'boolean', 'boolean', 'integer', 'integer'],
  'get_trending_locations(text,text,text,bool,bool,bool,bool,int,int) 9-arg overload exists'
);

-- ── 9. get_trending_locations respects limit_count ───────────────────────────

SELECT ok(
  (
    SELECT COUNT(*) <= 5
    FROM public.get_trending_locations(
      'trending', NULL, NULL, false, false, false, false, 5, 0
    )
  ),
  'get_trending_locations respects limit_count=5'
);

-- ── 10. offset_count skips rows ───────────────────────────────────────────────
-- Fetch page-1 and page-2 and confirm they contain different first rows
-- (only meaningful when the table has ≥ 2 rows; skip gracefully otherwise).

SELECT ok(
  (
    WITH page1 AS (
      SELECT id FROM public.get_trending_locations(
        'trending', NULL, NULL, false, false, false, false, 1, 0
      )
    ),
    page2 AS (
      SELECT id FROM public.get_trending_locations(
        'trending', NULL, NULL, false, false, false, false, 1, 1
      )
    ),
    total AS (SELECT COUNT(*) AS n FROM public.locations)
    SELECT
      CASE
        WHEN (SELECT n FROM total) < 2 THEN true  -- not enough data; trivially pass
        ELSE (SELECT id FROM page1) IS DISTINCT FROM (SELECT id FROM page2)
      END
  ),
  'offset_count=1 returns a different row than offset_count=0'
);

-- ── 11. metrics view unique index prevents duplicate (location_id, metric_date) ─

SELECT has_index(
  'public',
  'location_metrics_daily',
  'idx_location_metrics_daily_pk',
  'unique PK index exists on (location_id, metric_date)'
);

-- ── 12. metrics date index exists for fast time-range queries ─────────────────

SELECT has_index(
  'public',
  'location_metrics_daily',
  'idx_location_metrics_daily_date',
  'date DESC index exists for time-range queries'
);

SELECT * FROM finish();

ROLLBACK;

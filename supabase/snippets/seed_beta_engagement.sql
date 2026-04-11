-- =============================================================================
-- Beta engagement seed (profiles + locations)
-- =============================================================================
-- Run in Supabase SQL Editor (or psql) as a privileged role (postgres / service
-- role) so RLS does not block inserts as arbitrary users.
--
-- Map ranking thresholds (Dart: LocationRankingStandards) — this script does
-- NOT change those values; it inserts enough activity to cross them where possible:
--
--   Trending:   locations.check_in_count >= 4 (plus cohort rules). Multiple
--               check_ins per user per location are allowed (no UNIQUE there).
--
--   Popular:    favorites path needs favorite_count >= 3 AND
--               (favorite_count >= favoriteP75 OR favoriteP75 < 3) over the cohort.
--               One location with only 3 favorites can fail if favoriteP75 is high;
--               this script assigns one favorite per profile (up to 50 users) on
--               each of two hero locations so favorite_count clears percentiles.
--
--   Popular:    reviews absolute path needs review_count >= 10 on ONE spot —
--               requires 10 DISTINCT users (UNIQUE(location_id, user_id) on
--               reviews). If you have fewer than 10 profiles, this script only
--               adds one review per user spread across different locations
--               (ON CONFLICT DO NOTHING so real reviews are not overwritten).
--
-- Re-runnable: removes only rows tagged with note/comment '__seed_beta__' and
-- favorite pairs listed in temp table before re-insert.
--
-- Counters: do NOT UPDATE locations.check_in_count / favorite_count / rating /
-- review_count by hand — triggers on check_ins, favorites, and reviews handle it.
--
-- Optional: after running, if the app uses location_metrics_daily, refresh:
--   REFRESH MATERIALIZED VIEW public.location_metrics_daily;
--   (Use CONCURRENTLY only if your project has the required unique index.)
-- =============================================================================

BEGIN;

DELETE FROM public.check_ins
WHERE COALESCE(note, '') = '__seed_beta__';

DELETE FROM public.reviews
WHERE comment = '__seed_beta__';

CREATE TEMP TABLE seed_favorite_pairs (
  location_id uuid NOT NULL,
  user_id uuid NOT NULL,
  PRIMARY KEY (location_id, user_id)
) ON COMMIT DROP;

WITH
profiles_ordered AS (
  SELECT
    id,
    row_number() OVER (ORDER BY created_at ASC, id) AS rn
  FROM (
    SELECT id, created_at
    FROM public.profiles
    ORDER BY created_at ASC, id
    LIMIT 50
  ) profile_subset
),
locations_curated AS (
  SELECT
    id,
    row_number() OVER (ORDER BY id) AS rn
  FROM public.locations
  WHERE submitted_by IS NULL
),
hero_trending AS (
  SELECT id FROM locations_curated WHERE rn = 1
  UNION ALL
  SELECT id FROM locations_curated WHERE rn = 2
  UNION ALL
  SELECT id FROM locations_curated WHERE rn = 3
),
first_profile AS (
  SELECT id FROM profiles_ordered WHERE rn = 1
),
trending_checkins AS (
  SELECT h.id AS location_id, fp.id AS user_id
  FROM hero_trending h
  CROSS JOIN first_profile fp
  CROSS JOIN generate_series(1, 5) AS g(n)
  WHERE EXISTS (SELECT 1 FROM profiles_ordered LIMIT 1)
    AND EXISTS (SELECT 1 FROM locations_curated LIMIT 1)
)
INSERT INTO public.check_ins (location_id, user_id, note, photos)
SELECT location_id, user_id, '__seed_beta__', '[]'::jsonb
FROM trending_checkins;

-- Popular via favorites: one favorite per profile (up to 50) on hero locations
-- rn = 4 and rn = 7 (curated only), so favorite_count matches user count on each.
WITH
profiles_ordered AS (
  SELECT id, row_number() OVER (ORDER BY created_at ASC, id) AS rn
  FROM (
    SELECT id, created_at
    FROM public.profiles
    ORDER BY created_at ASC, id
    LIMIT 50
  ) profile_subset
),
locations_curated AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM public.locations
  WHERE submitted_by IS NULL
),
fav_pairs AS (
  SELECT l.id AS location_id, p.id AS user_id
  FROM locations_curated l
  CROSS JOIN profiles_ordered p
  WHERE l.rn = 4
    AND (SELECT count(*)::int FROM public.profiles) >= 3
    AND EXISTS (SELECT 1 FROM locations_curated WHERE rn = 4)
  UNION ALL
  SELECT l.id AS location_id, p.id AS user_id
  FROM locations_curated l
  CROSS JOIN profiles_ordered p
  WHERE l.rn = 7
    AND (SELECT count(*)::int FROM public.profiles) >= 3
    AND EXISTS (SELECT 1 FROM locations_curated WHERE rn = 7)
)
INSERT INTO seed_favorite_pairs (location_id, user_id)
SELECT location_id, user_id FROM fav_pairs;

DELETE FROM public.favorites f
USING seed_favorite_pairs s
WHERE f.location_id = s.location_id AND f.user_id = s.user_id;

INSERT INTO public.favorites (location_id, user_id)
SELECT location_id, user_id FROM seed_favorite_pairs
ON CONFLICT (location_id, user_id) DO NOTHING;

-- Reviews: 10 users on one hero (5th curated location) when possible; else 1:1 spread.
WITH
profiles_ordered AS (
  SELECT id, row_number() OVER (ORDER BY created_at ASC, id) AS rn
  FROM (
    SELECT id, created_at
    FROM public.profiles
    ORDER BY created_at ASC, id
    LIMIT 50
  ) profile_subset
),
locations_curated AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM public.locations
  WHERE submitted_by IS NULL
),
pc AS (SELECT count(*)::int AS c FROM public.profiles),
lc AS (SELECT count(*)::int AS c FROM locations_curated),
hero_reviews_dense AS (
  SELECT l.id AS location_id, p.id AS user_id
  FROM locations_curated l
  CROSS JOIN profiles_ordered p
  WHERE l.rn = 5
    AND p.rn BETWEEN 1 AND 10
    AND (SELECT c FROM pc) >= 10
    AND EXISTS (SELECT 1 FROM locations_curated WHERE rn = 5)
),
hero_reviews_sparse AS (
  SELECT l.id AS location_id, p.id AS user_id
  FROM profiles_ordered p
  INNER JOIN locations_curated l ON l.rn = p.rn
  WHERE (SELECT c FROM pc) < 10
    AND (SELECT c FROM lc) > 0
    AND p.rn <= (SELECT least((SELECT c FROM pc), (SELECT c FROM lc)))
),
-- Popular via reviews when <10 global users: stack 5 rating-5 reviews on location rn=8
-- (rating >= 4, reviewCount >= 3, and reviewP75 is usually 0 in a thin cohort).
hero_reviews_popular_mid AS (
  SELECT l.id AS location_id, p.id AS user_id
  FROM locations_curated l
  CROSS JOIN profiles_ordered p
  WHERE l.rn = 8
    AND p.rn BETWEEN 1 AND least(5, (SELECT c FROM pc))
    AND (SELECT c FROM pc) >= 3
    AND (SELECT c FROM pc) < 10
    AND EXISTS (SELECT 1 FROM locations_curated WHERE rn = 8)
)
INSERT INTO public.reviews (location_id, user_id, rating, comment, photos)
SELECT location_id, user_id, 5, '__seed_beta__', '[]'::jsonb
FROM (
  SELECT * FROM hero_reviews_dense
  UNION ALL
  SELECT * FROM hero_reviews_sparse
  UNION ALL
  SELECT * FROM hero_reviews_popular_mid
) x
WHERE EXISTS (SELECT 1 FROM profiles_ordered LIMIT 1)
ON CONFLICT (location_id, user_id) DO NOTHING;

COMMIT;

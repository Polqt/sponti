-- Migration: ranked search pipeline using full-text search, trigram similarity,
-- popularity, proximity, open-now heuristics, and user-history boosts.
-- This ships as a new RPC so the app can roll it out behind a feature flag.

CREATE OR REPLACE FUNCTION public.search_locations_ranked(
  search_query TEXT,
  viewer_lat DOUBLE PRECISION DEFAULT NULL,
  viewer_lng DOUBLE PRECISION DEFAULT NULL,
  limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  address TEXT,
  landmark TEXT,
  price_range TEXT,
  photos JSONB,
  tags JSONB,
  rating DOUBLE PRECISION,
  review_count INTEGER,
  check_in_count INTEGER,
  is_hidden_gem BOOLEAN,
  is_verified BOOLEAN,
  has_wifi BOOLEAN,
  is_pet_friendly BOOLEAN,
  has_parking BOOLEAN,
  open_time TEXT,
  close_time TEXT,
  days_open JSONB,
  special_hours_note TEXT,
  contact_number TEXT,
  website_url TEXT,
  instagram_handle TEXT,
  submitted_by UUID,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_seeded BOOLEAN,
  seeded_at TIMESTAMPTZ,
  distance_km DOUBLE PRECISION
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
  WITH search_input AS (
    SELECT
      trim(coalesce(search_query, '')) AS raw_query,
      lower(trim(coalesce(search_query, ''))) AS lowered_query,
      plainto_tsquery('english', trim(coalesce(search_query, ''))) AS ts_query,
      auth.uid() AS viewer_id,
      (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila') AS local_now
  ),
  favorite_counts AS (
    SELECT
      f.location_id,
      COUNT(*)::integer AS favorite_count
    FROM public.favorites f
    GROUP BY f.location_id
  ),
  recent_metrics AS (
    SELECT
      m.location_id,
      COALESCE(
        SUM(m.check_in_count) FILTER (
          WHERE m.metric_date >= CURRENT_DATE - 6
        ),
        0
      )::integer AS recent_check_ins,
      COALESCE(
        SUM(m.review_count) FILTER (
          WHERE m.metric_date >= CURRENT_DATE - 29
        ),
        0
      )::integer AS recent_reviews,
      COALESCE(
        SUM(m.favorite_count) FILTER (
          WHERE m.metric_date >= CURRENT_DATE - 29
        ),
        0
      )::integer AS recent_favorites
    FROM public.location_metrics_daily m
    GROUP BY m.location_id
  ),
  user_history AS (
    SELECT
      location_id,
      bool_or(has_favorite) AS has_favorite,
      bool_or(has_check_in) AS has_check_in
    FROM (
      SELECT
        f.location_id,
        true AS has_favorite,
        false AS has_check_in
      FROM public.favorites f
      CROSS JOIN search_input si
      WHERE si.viewer_id IS NOT NULL
        AND f.user_id = si.viewer_id
      UNION ALL
      SELECT
        c.location_id,
        false AS has_favorite,
        true AS has_check_in
      FROM public.check_ins c
      CROSS JOIN search_input si
      WHERE si.viewer_id IS NOT NULL
        AND c.user_id = si.viewer_id
    ) history
    GROUP BY location_id
  ),
  candidates AS (
    SELECT
      l.*,
      CASE
        WHEN viewer_lat IS NULL OR viewer_lng IS NULL THEN NULL
        ELSE ST_Distance(
          ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326)::geography,
          ST_SetSRID(ST_MakePoint(viewer_lng, viewer_lat), 4326)::geography
        ) / 1000.0
      END AS distance_km,
      ts_rank(l.fts, si.ts_query) AS text_rank,
      GREATEST(
        similarity(lower(l.name), si.lowered_query),
        similarity(lower(coalesce(l.address, '')), si.lowered_query),
        similarity(lower(coalesce(l.landmark, '')), si.lowered_query)
      ) AS trigram_score,
      COALESCE(fc.favorite_count, 0) AS favorite_count,
      COALESCE(rm.recent_check_ins, 0) AS recent_check_ins,
      COALESCE(rm.recent_reviews, 0) AS recent_reviews,
      COALESCE(rm.recent_favorites, 0) AS recent_favorites,
      COALESCE(uh.has_favorite, false) AS has_favorite,
      COALESCE(uh.has_check_in, false) AS has_check_in,
      CASE
        WHEN l.open_time IS NULL OR l.close_time IS NULL THEN 0
        WHEN NOT EXISTS (
          SELECT 1
          FROM jsonb_array_elements_text(coalesce(l.days_open, '[]'::jsonb)) day_value
          WHERE day_value::integer = EXTRACT(ISODOW FROM si.local_now)::integer
        ) THEN 0
        WHEN l.close_time < l.open_time THEN CASE
          WHEN to_char(si.local_now, 'HH24:MI') >= l.open_time
            OR to_char(si.local_now, 'HH24:MI') <= l.close_time
          THEN 1
          ELSE 0
        END
        ELSE CASE
          WHEN to_char(si.local_now, 'HH24:MI') BETWEEN l.open_time AND l.close_time
          THEN 1
          ELSE 0
        END
      END AS open_now_score
    FROM public.locations l
    CROSS JOIN search_input si
    LEFT JOIN favorite_counts fc ON fc.location_id = l.id
    LEFT JOIN recent_metrics rm ON rm.location_id = l.id
    LEFT JOIN user_history uh ON uh.location_id = l.id
    WHERE si.raw_query <> ''
      AND (
        l.fts @@ si.ts_query
        OR lower(l.name) LIKE '%' || si.lowered_query || '%'
        OR lower(coalesce(l.address, '')) LIKE '%' || si.lowered_query || '%'
        OR lower(coalesce(l.landmark, '')) LIKE '%' || si.lowered_query || '%'
        OR similarity(lower(l.name), si.lowered_query) > 0.12
        OR similarity(lower(coalesce(l.address, '')), si.lowered_query) > 0.10
        OR EXISTS (
          SELECT 1
          FROM jsonb_array_elements_text(coalesce(l.tags, '[]'::jsonb)) tag_value
          WHERE lower(tag_value) LIKE '%' || si.lowered_query || '%'
        )
      )
  )
  SELECT
    c.id,
    c.name,
    c.description,
    c.category,
    c.latitude,
    c.longitude,
    c.address,
    c.landmark,
    c.price_range,
    c.photos,
    c.tags,
    c.rating,
    c.review_count,
    c.check_in_count,
    c.is_hidden_gem,
    c.is_verified,
    c.has_wifi,
    c.is_pet_friendly,
    c.has_parking,
    c.open_time,
    c.close_time,
    c.days_open,
    c.special_hours_note,
    c.contact_number,
    c.website_url,
    c.instagram_handle,
    c.submitted_by,
    c.created_at,
    c.updated_at,
    c.is_seeded,
    c.seeded_at,
    c.distance_km
  FROM candidates c
  ORDER BY
    (
      COALESCE(c.text_rank, 0) * 4.00 +
      COALESCE(c.trigram_score, 0) * 2.50 +
      LN(1 + COALESCE(c.favorite_count, 0)) * 0.35 +
      LN(1 + COALESCE(c.recent_favorites, 0)) * 0.15 +
      LN(1 + COALESCE(c.recent_check_ins, 0)) * 0.55 +
      LN(1 + COALESCE(c.recent_reviews, 0)) * 0.20 +
      CASE
        WHEN c.distance_km IS NULL THEN 0
        ELSE GREATEST(0, 1 - LEAST(c.distance_km, 20) / 20) * 0.60
      END +
      c.open_now_score * 0.35 +
      CASE WHEN c.has_favorite THEN 0.45 ELSE 0 END +
      CASE WHEN c.has_check_in THEN 0.25 ELSE 0 END
    ) DESC,
    COALESCE(c.distance_km, 1000000) ASC,
    c.rating DESC,
    c.review_count DESC,
    c.created_at DESC,
    c.id DESC
  LIMIT GREATEST(limit_count, 1);
$$;

GRANT EXECUTE ON FUNCTION public.search_locations_ranked(
  TEXT,
  DOUBLE PRECISION,
  DOUBLE PRECISION,
  INTEGER
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.search_locations_ranked(
  TEXT,
  DOUBLE PRECISION,
  DOUBLE PRECISION,
  INTEGER
) TO anon;

-- Migration: push more explore filtering into SQL so the client does not
-- fetch broad result sets and trim them locally on every filter change.

DROP FUNCTION IF EXISTS public.get_trending_locations(TEXT, TEXT, INTEGER);

CREATE OR REPLACE FUNCTION public.get_trending_locations(
  ranking_filter TEXT DEFAULT 'trending',
  category_filter TEXT DEFAULT NULL,
  price_filter TEXT DEFAULT NULL,
  now_open_only BOOLEAN DEFAULT false,
  has_wifi_only BOOLEAN DEFAULT false,
  pet_friendly_only BOOLEAN DEFAULT false,
  has_parking_only BOOLEAN DEFAULT false,
  limit_count INTEGER DEFAULT 20
)
RETURNS SETOF public.locations
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  WITH normalized_filter AS (
    SELECT CASE LOWER(COALESCE(ranking_filter, 'trending'))
      WHEN 'popular' THEN 'popular'
      WHEN 'lowkey' THEN 'lowkey'
      WHEN 'new' THEN 'new'
      ELSE 'trending'
    END AS value
  ),
  current_clock AS (
    SELECT CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila' AS local_now
  ),
  favorite_counts AS (
    SELECT
      f.location_id,
      COUNT(*)::INTEGER AS favorite_count
    FROM public.favorites f
    GROUP BY f.location_id
  ),
  category_suggestions AS (
    SELECT
      s.category,
      COUNT(*)::INTEGER AS suggested_count
    FROM public.suggestions s
    GROUP BY s.category
  )
  SELECT l.*
  FROM public.locations l
  CROSS JOIN normalized_filter nf
  CROSS JOIN current_clock cc
  LEFT JOIN favorite_counts fc ON fc.location_id = l.id
  LEFT JOIN category_suggestions cs ON cs.category = l.category
  WHERE (category_filter IS NULL OR l.category = category_filter)
    AND (price_filter IS NULL OR l.price_range = price_filter)
    AND (has_wifi_only = false OR l.has_wifi = true)
    AND (pet_friendly_only = false OR l.is_pet_friendly = true)
    AND (has_parking_only = false OR l.has_parking = true)
    AND (nf.value <> 'new' OR l.is_seeded = true)
    AND (
      now_open_only = false
      OR (
        l.open_time IS NOT NULL
        AND l.close_time IS NOT NULL
        AND EXISTS (
          SELECT 1
          FROM jsonb_array_elements_text(COALESCE(l.days_open, '[]'::jsonb)) day_value
          WHERE day_value::INTEGER = EXTRACT(ISODOW FROM cc.local_now)::INTEGER
        )
        AND (
          CASE
            WHEN l.close_time < l.open_time THEN
              to_char(cc.local_now, 'HH24:MI') >= l.open_time
              OR to_char(cc.local_now, 'HH24:MI') <= l.close_time
            ELSE
              to_char(cc.local_now, 'HH24:MI') BETWEEN l.open_time AND l.close_time
          END
        )
      )
    )
  ORDER BY
    CASE
      WHEN nf.value = 'trending' THEN l.check_in_count
    END DESC NULLS LAST,
    CASE
      WHEN nf.value = 'popular' THEN COALESCE(fc.favorite_count, 0)
    END DESC NULLS LAST,
    CASE
      WHEN nf.value = 'lowkey' THEN COALESCE(cs.suggested_count, 0)
    END DESC NULLS LAST,
    CASE
      WHEN nf.value = 'new' THEN COALESCE(l.seeded_at, l.created_at)
    END DESC NULLS LAST,
    CASE
      WHEN nf.value = 'lowkey' THEN CASE WHEN l.is_hidden_gem THEN 1 ELSE 0 END
    END DESC NULLS LAST,
    CASE
      WHEN nf.value = 'lowkey' THEN l.check_in_count
    END ASC NULLS LAST,
    COALESCE(fc.favorite_count, 0) DESC,
    l.check_in_count DESC,
    l.review_count DESC,
    l.rating DESC,
    COALESCE(l.seeded_at, l.created_at) DESC,
    l.created_at DESC
  LIMIT GREATEST(limit_count, 1);
$$;

GRANT EXECUTE ON FUNCTION public.get_trending_locations(
  TEXT,
  TEXT,
  TEXT,
  BOOLEAN,
  BOOLEAN,
  BOOLEAN,
  BOOLEAN,
  INTEGER
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_trending_locations(
  TEXT,
  TEXT,
  TEXT,
  BOOLEAN,
  BOOLEAN,
  BOOLEAN,
  BOOLEAN,
  INTEGER
) TO anon;

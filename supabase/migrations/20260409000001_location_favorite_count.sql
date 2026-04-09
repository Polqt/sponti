-- Denormalized favorite_count on locations for map/explore ranking and client parity.
-- Kept in sync by triggers on public.favorites.

ALTER TABLE public.locations
  ADD COLUMN IF NOT EXISTS favorite_count INTEGER NOT NULL DEFAULT 0;

UPDATE public.locations l
SET favorite_count = (
  SELECT COUNT(*)::INTEGER FROM public.favorites f WHERE f.location_id = l.id
);

CREATE OR REPLACE FUNCTION public.bump_location_favorite_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.locations
    SET favorite_count = favorite_count + 1
    WHERE id = NEW.location_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.locations
    SET favorite_count = GREATEST(favorite_count - 1, 0)
    WHERE id = OLD.location_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS on_favorite_change ON public.favorites;
CREATE TRIGGER on_favorite_change
  AFTER INSERT OR DELETE ON public.favorites
  FOR EACH ROW
  EXECUTE FUNCTION public.bump_location_favorite_count();

-- Explore RPC: order Popular by denormalized column (same values as live COUNT after triggers).
DROP FUNCTION IF EXISTS public.get_trending_locations(
  TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER
);

CREATE OR REPLACE FUNCTION public.get_trending_locations(
  ranking_filter    TEXT    DEFAULT 'trending',
  category_filter   TEXT    DEFAULT NULL,
  price_filter      TEXT    DEFAULT NULL,
  now_open_only     BOOLEAN DEFAULT false,
  has_wifi_only     BOOLEAN DEFAULT false,
  pet_friendly_only BOOLEAN DEFAULT false,
  has_parking_only  BOOLEAN DEFAULT false,
  limit_count       INTEGER DEFAULT 20,
  offset_count      INTEGER DEFAULT 0
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
      WHEN 'lowkey'  THEN 'lowkey'
      WHEN 'new'     THEN 'new'
      ELSE 'trending'
    END AS value
  ),
  current_clock AS (
    SELECT CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila' AS local_now
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
  LEFT JOIN category_suggestions cs ON cs.category = l.category
  WHERE (category_filter IS NULL OR l.category = category_filter)
    AND (price_filter IS NULL OR l.price_range = price_filter)
    AND (has_wifi_only     = false OR l.has_wifi        = true)
    AND (pet_friendly_only = false OR l.is_pet_friendly = true)
    AND (has_parking_only  = false OR l.has_parking     = true)
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
    CASE WHEN nf.value = 'trending' THEN l.check_in_count END DESC NULLS LAST,
    CASE WHEN nf.value = 'popular'  THEN l.favorite_count END DESC NULLS LAST,
    CASE WHEN nf.value = 'lowkey'   THEN COALESCE(cs.suggested_count, 0) END DESC NULLS LAST,
    CASE WHEN nf.value = 'new'      THEN COALESCE(l.seeded_at, l.created_at) END DESC NULLS LAST,
    CASE WHEN nf.value = 'lowkey'   THEN CASE WHEN l.is_hidden_gem THEN 1 ELSE 0 END END DESC NULLS LAST,
    CASE WHEN nf.value = 'lowkey'   THEN l.check_in_count END ASC NULLS LAST,
    l.favorite_count DESC,
    l.check_in_count DESC,
    l.review_count DESC,
    l.rating DESC,
    COALESCE(l.seeded_at, l.created_at) DESC,
    l.created_at DESC
  LIMIT  GREATEST(limit_count, 1)
  OFFSET GREATEST(offset_count, 0);
$$;

GRANT EXECUTE ON FUNCTION public.get_trending_locations(
  TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_trending_locations(
  TEXT, TEXT, TEXT, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER
) TO anon;

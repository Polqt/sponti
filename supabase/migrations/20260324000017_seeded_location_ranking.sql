-- Migration: add explicit seeded metadata for locations and align ranking filters.
-- `new` should surface seeded locations ordered by the latest seeded timestamp, while:
-- - trending = check-in count
-- - popular = favorite count
-- - lowkey = suggested spot count by category

ALTER TABLE public.locations
  ADD COLUMN IF NOT EXISTS is_seeded BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS seeded_at TIMESTAMPTZ;

UPDATE public.locations
SET
  is_seeded = true,
  seeded_at = COALESCE(seeded_at, created_at)
WHERE submitted_by IS NULL
  AND (is_seeded = false OR seeded_at IS NULL);

CREATE INDEX IF NOT EXISTS idx_locations_seeded_at
  ON public.locations (seeded_at DESC)
  WHERE is_seeded = true;

CREATE INDEX IF NOT EXISTS idx_favorites_location
  ON public.favorites(location_id);

CREATE INDEX IF NOT EXISTS idx_suggestions_category
  ON public.suggestions(category);

CREATE OR REPLACE FUNCTION public.get_trending_locations(
  ranking_filter TEXT DEFAULT 'trending',
  category_filter TEXT DEFAULT NULL,
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
  LEFT JOIN favorite_counts fc ON fc.location_id = l.id
  LEFT JOIN category_suggestions cs ON cs.category = l.category
  WHERE (category_filter IS NULL OR l.category = category_filter)
    AND (nf.value <> 'new' OR l.is_seeded = true)
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

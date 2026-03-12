-- Migration: Profile/location helper RPC functions
-- Adds profile stats and trending location filters.

CREATE OR REPLACE FUNCTION public.get_user_stats(user_id UUID)
RETURNS TABLE (
  check_in_count INTEGER,
  favorites_count INTEGER,
  spots_suggested INTEGER
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    COALESCE(
      (
        SELECT p.total_check_ins
        FROM public.profiles p
        WHERE p.id = get_user_stats.user_id
      ),
      0
    )::INTEGER AS check_in_count,
    COALESCE(
      (
        SELECT COUNT(*)::INTEGER
        FROM public.favorites f
        WHERE f.user_id = get_user_stats.user_id
      ),
      0
    )::INTEGER AS favorites_count,
    COALESCE(
      (
        SELECT COUNT(*)::INTEGER
        FROM public.suggestions s
        WHERE s.user_id = get_user_stats.user_id
      ),
      0
    )::INTEGER AS spots_suggested;
$$;

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
  WITH recent_checkins AS (
    SELECT
      c.location_id,
      COUNT(*) FILTER (WHERE c.created_at >= now() - INTERVAL '7 days')
        ::INTEGER AS recent_check_ins,
      COUNT(*)::INTEGER AS lifetime_check_ins
    FROM public.check_ins c
    GROUP BY c.location_id
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
  LEFT JOIN recent_checkins rc ON rc.location_id = l.id
  LEFT JOIN favorite_counts fc ON fc.location_id = l.id
  LEFT JOIN category_suggestions cs ON cs.category = l.category
  WHERE category_filter IS NULL OR l.category = category_filter
  ORDER BY
    CASE LOWER(COALESCE(ranking_filter, 'trending'))
      WHEN 'popular' THEN COALESCE(fc.favorite_count, 0)
      WHEN 'lowkey' THEN COALESCE(cs.suggested_count, 0)
      ELSE COALESCE(rc.recent_check_ins, 0)
    END DESC,
    CASE
      WHEN LOWER(COALESCE(ranking_filter, 'trending')) = 'lowkey'
      THEN CASE WHEN l.is_hidden_gem THEN 1 ELSE 0 END
    END DESC NULLS LAST,
    CASE
      WHEN LOWER(COALESCE(ranking_filter, 'trending')) = 'lowkey'
      THEN COALESCE(rc.lifetime_check_ins, l.check_in_count, 0)
    END ASC NULLS LAST,
    CASE
      WHEN LOWER(COALESCE(ranking_filter, 'trending')) <> 'lowkey'
      THEN COALESCE(rc.lifetime_check_ins, l.check_in_count, 0)
    END DESC NULLS LAST,
    COALESCE(fc.favorite_count, 0) DESC,
    l.review_count DESC,
    l.rating DESC,
    l.created_at DESC
  LIMIT GREATEST(limit_count, 1);
$$;

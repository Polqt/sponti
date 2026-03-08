-- Migration: RPC functions (nearby locations, full-text search, location with stats)
-- Requires: postgis extension (migration 0001), locations table (migration 0003)

-- NEARBY LOCATIONS (PostGIS)
-- Called by: _client.rpc('get_nearby_locations', params: {lat, lng, radius_km})
-- Returns: all location columns + distance_km, sorted by distance
CREATE OR REPLACE FUNCTION get_nearby_locations(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (
  id UUID, name TEXT, description TEXT, category TEXT,
  latitude DOUBLE PRECISION, longitude DOUBLE PRECISION,
  address TEXT, landmark TEXT, price_range TEXT,
  photos JSONB, tags JSONB, rating DOUBLE PRECISION,
  review_count INTEGER, check_in_count INTEGER,
  is_hidden_gem BOOLEAN, is_verified BOOLEAN,
  has_wifi BOOLEAN, is_pet_friendly BOOLEAN, has_parking BOOLEAN,
  open_time TEXT, close_time TEXT, days_open JSONB,
  special_hours_note TEXT, contact_number TEXT,
  website_url TEXT, instagram_handle TEXT, submitted_by UUID,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ,
  distance_km DOUBLE PRECISION
)
LANGUAGE sql STABLE
AS $$
  SELECT
    l.id, l.name, l.description, l.category,
    l.latitude, l.longitude,
    l.address, l.landmark, l.price_range,
    l.photos, l.tags, l.rating,
    l.review_count, l.check_in_count,
    l.is_hidden_gem, l.is_verified,
    l.has_wifi, l.is_pet_friendly, l.has_parking,
    l.open_time, l.close_time, l.days_open,
    l.special_hours_note, l.contact_number,
    l.website_url, l.instagram_handle, l.submitted_by,
    l.created_at, l.updated_at,
    ST_Distance(
      ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326)::geography,
      ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
    ) / 1000.0 AS distance_km
  FROM public.locations l
  WHERE ST_DWithin(
    ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326)::geography,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    radius_km * 1000
  )
  ORDER BY distance_km ASC;
$$;

-- FULL-TEXT SEARCH
-- Called by: _client.rpc('search_locations', params: {search_query})
-- Uses the generated tsvector column `fts` on locations, plus ILIKE fallback
CREATE OR REPLACE FUNCTION search_locations(search_query TEXT)
RETURNS SETOF public.locations
LANGUAGE sql STABLE
AS $$
  SELECT *
  FROM public.locations
  WHERE
    fts @@ plainto_tsquery('english', search_query)
    OR name ILIKE '%' || search_query || '%'
    OR description ILIKE '%' || search_query || '%'
  ORDER BY
    ts_rank(fts, plainto_tsquery('english', search_query)) DESC
  LIMIT 50;
$$;

-- LOCATION WITH STATS
-- Called by: _client.rpc('get_location_with_stats', params: {location_uuid})
CREATE OR REPLACE FUNCTION get_location_with_stats(location_uuid UUID)
RETURNS SETOF public.locations
LANGUAGE sql STABLE
AS $$
  SELECT l.*
  FROM public.locations l
  WHERE l.id = location_uuid;
$$;

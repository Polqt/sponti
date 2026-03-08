# Database Schema: Sponti

**Database**: Supabase (PostgreSQL with PostGIS)
**Extensions**: `uuid-ossp`, `postgis`, `pg_trgm` (trigram for fuzzy search)
**Storage Buckets**: `location-photos`, `avatars`

---

## Tables

### `profiles`
**Purpose**: User profiles, auto-created on auth signup

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, REFERENCES auth.users(id) ON DELETE CASCADE | Same as auth user ID |
| username | TEXT | UNIQUE | Optional display handle |
| full_name | TEXT | | From OAuth provider or user-set |
| avatar_url | TEXT | | URL in `avatars` storage bucket |
| bio | TEXT | | Short user bio |
| total_check_ins | INTEGER | DEFAULT 0 | Denormalized counter |
| total_reviews | INTEGER | DEFAULT 0 | Denormalized counter |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |
| updated_at | TIMESTAMPTZ | DEFAULT now() | |

**Indexes**:
- `idx_profiles_username` on `username` (for uniqueness lookups)

**RLS Policies**:
- SELECT: Anyone can read any profile
- INSERT: Only `auth.uid() = id`
- UPDATE: Only `auth.uid() = id`
- DELETE: Only `auth.uid() = id`

**Triggers**:
- `on_auth_user_created`: Auto-creates profile row with full_name and avatar_url from auth metadata

---

### `locations`
**Purpose**: All discoverable spots/places in Bacolod

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| name | TEXT | NOT NULL | Location/spot name |
| description | TEXT | DEFAULT '' | |
| category | TEXT | NOT NULL, CHECK (category IN ('food', 'coffee', 'nature', 'nightlife', 'arts', 'activities')) | Maps to `LocationCategory` enum |
| latitude | DOUBLE PRECISION | NOT NULL | GPS latitude |
| longitude | DOUBLE PRECISION | NOT NULL | GPS longitude |
| address | TEXT | DEFAULT '' | Street address |
| landmark | TEXT | | Nearby landmark for navigation |
| price_range | TEXT | DEFAULT 'budget', CHECK (price_range IN ('free', 'budget', 'moderate', 'expensive')) | Maps to `PriceRange` enum |
| photos | JSONB | DEFAULT '[]' | Array of photo URLs |
| tags | JSONB | DEFAULT '[]' | Array of tag strings |
| rating | DOUBLE PRECISION | DEFAULT 0.0 | Average rating (denormalized) |
| review_count | INTEGER | DEFAULT 0 | Total reviews (denormalized) |
| check_in_count | INTEGER | DEFAULT 0 | Total check-ins (denormalized) |
| is_hidden_gem | BOOLEAN | DEFAULT false | Curated hidden gem flag |
| is_verified | BOOLEAN | DEFAULT false | Admin-verified location |
| has_wifi | BOOLEAN | DEFAULT false | |
| is_pet_friendly | BOOLEAN | DEFAULT false | |
| has_parking | BOOLEAN | DEFAULT false | |
| open_time | TEXT | | Format: "HH:MM" (24h) |
| close_time | TEXT | | Format: "HH:MM" (24h) |
| days_open | JSONB | DEFAULT '[]' | Array of integers 1-7 (Monday=1) |
| special_hours_note | TEXT | | e.g., "Closed on holidays" |
| contact_number | TEXT | | |
| website_url | TEXT | | |
| instagram_handle | TEXT | | Without @ prefix |
| submitted_by | UUID | REFERENCES profiles(id) | User who submitted (if community-sourced) |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |
| updated_at | TIMESTAMPTZ | | |

**Indexes**:
- `idx_locations_category` on `category` (for category filtering)
- `idx_locations_rating` on `rating DESC` (for sorting by rating)
- `idx_locations_geo` on `latitude, longitude` (for proximity queries)
- `idx_locations_hidden_gem` on `is_hidden_gem` WHERE `is_hidden_gem = true`
- GIN index on `name` and `description` for full-text search (tsvector)

**RLS Policies**:
- SELECT: Anyone can read (public)
- INSERT: Authenticated users only
- UPDATE: Admin only (or submitted_by = auth.uid())
- DELETE: Admin only

---

### `reviews`
**Purpose**: User reviews for locations

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| location_id | UUID | NOT NULL, REFERENCES locations(id) ON DELETE CASCADE | |
| user_id | UUID | NOT NULL, REFERENCES profiles(id) ON DELETE CASCADE | |
| rating | SMALLINT | NOT NULL, CHECK (rating >= 1 AND rating <= 5) | 1-5 star rating |
| comment | TEXT | DEFAULT '' | Review text |
| photos | JSONB | DEFAULT '[]' | Array of photo URLs |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |
| updated_at | TIMESTAMPTZ | | |

**Indexes**:
- `idx_reviews_location` on `location_id` (for fetching reviews by location)
- `idx_reviews_user` on `user_id` (for fetching user's reviews)
- UNIQUE constraint on `(location_id, user_id)` — one review per user per location

**RLS Policies**:
- SELECT: Anyone can read
- INSERT: Authenticated, user_id = auth.uid()
- UPDATE: Only user_id = auth.uid()
- DELETE: Only user_id = auth.uid()

**Triggers**:
- `on_review_insert`: Updates `locations.rating` (avg) and `locations.review_count` (+1), updates `profiles.total_reviews` (+1)
- `on_review_delete`: Recalculates `locations.rating` and `locations.review_count` (-1), updates `profiles.total_reviews` (-1)

---

### `check_ins`
**Purpose**: User check-ins at locations (proof of visit)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| location_id | UUID | NOT NULL, REFERENCES locations(id) ON DELETE CASCADE | |
| user_id | UUID | NOT NULL, REFERENCES profiles(id) ON DELETE CASCADE | |
| note | TEXT | | Optional check-in note |
| photo_url | TEXT | | Optional check-in photo |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |

**Indexes**:
- `idx_checkins_location` on `location_id`
- `idx_checkins_user` on `user_id`
- `idx_checkins_user_location_date` on `(user_id, location_id, created_at::date)` — for once-per-day constraint

**RLS Policies**:
- SELECT: Anyone can read
- INSERT: Authenticated, user_id = auth.uid()
- DELETE: Only user_id = auth.uid()

**Triggers**:
- `on_checkin_insert`: Updates `locations.check_in_count` (+1), updates `profiles.total_check_ins` (+1)

---

### `favorites`
**Purpose**: User's saved/bookmarked locations

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| location_id | UUID | NOT NULL, REFERENCES locations(id) ON DELETE CASCADE | |
| user_id | UUID | NOT NULL, REFERENCES profiles(id) ON DELETE CASCADE | |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |

**Indexes**:
- UNIQUE constraint on `(location_id, user_id)` — can't favorite same location twice
- `idx_favorites_user` on `user_id` (for fetching user's favorites)

**RLS Policies**:
- SELECT: Only user_id = auth.uid() (users see only their own favorites)
- INSERT: Authenticated, user_id = auth.uid()
- DELETE: Only user_id = auth.uid()

---

### `suggestions`
**Purpose**: Community-submitted spot suggestions for admin review

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| user_id | UUID | NOT NULL, REFERENCES profiles(id) ON DELETE CASCADE | |
| name | TEXT | NOT NULL | Suggested spot name |
| description | TEXT | | |
| category | TEXT | NOT NULL | Same enum as locations |
| address | TEXT | NOT NULL | |
| latitude | DOUBLE PRECISION | | Optional if user pins on map |
| longitude | DOUBLE PRECISION | | |
| reason | TEXT | | "Why should we add this?" |
| status | TEXT | DEFAULT 'pending', CHECK (status IN ('pending', 'approved', 'rejected')) | |
| admin_note | TEXT | | Admin feedback |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |

**Indexes**:
- `idx_suggestions_user` on `user_id`
- `idx_suggestions_status` on `status`

**RLS Policies**:
- SELECT: user_id = auth.uid() (users see only their own suggestions)
- INSERT: Authenticated, user_id = auth.uid()
- UPDATE: Admin only (for status changes)

---

### `location_photos`
**Purpose**: Community-submitted photos for locations (separate from owner's photos array)

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | |
| location_id | UUID | NOT NULL, REFERENCES locations(id) ON DELETE CASCADE | |
| user_id | UUID | NOT NULL, REFERENCES profiles(id) ON DELETE CASCADE | |
| photo_url | TEXT | NOT NULL | URL in storage |
| caption | TEXT | | |
| created_at | TIMESTAMPTZ | DEFAULT now(), NOT NULL | |

**Indexes**:
- `idx_location_photos_location` on `location_id`

**RLS Policies**:
- SELECT: Anyone can read
- INSERT: Authenticated, user_id = auth.uid()
- DELETE: Only user_id = auth.uid() or admin

---

## RPC Functions

### `get_nearby_locations(lat DOUBLE, lng DOUBLE, radius_km DOUBLE)`
**Returns**: locations rows + `distance_km` column, sorted by distance ASC
**Method**: Uses PostGIS `ST_DWithin` and `ST_Distance` with geography casting
```sql
CREATE OR REPLACE FUNCTION get_nearby_locations(lat DOUBLE PRECISION, lng DOUBLE PRECISION, radius_km DOUBLE PRECISION DEFAULT 5.0)
RETURNS TABLE (/* all location columns + distance_km */)
LANGUAGE sql STABLE
AS $$
  SELECT l.*,
         ST_Distance(
           ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326)::geography,
           ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography
         ) / 1000.0 AS distance_km
  FROM locations l
  WHERE ST_DWithin(
    ST_SetSRID(ST_MakePoint(l.longitude, l.latitude), 4326)::geography,
    ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography,
    radius_km * 1000
  )
  ORDER BY distance_km ASC;
$$;
```

### `search_locations(search_query TEXT)`
**Returns**: locations matching full-text search on name + description + tags
**Method**: Uses `to_tsvector` and `to_tsquery` with trigram fallback
```sql
CREATE OR REPLACE FUNCTION search_locations(search_query TEXT)
RETURNS SETOF locations
LANGUAGE sql STABLE
AS $$
  SELECT *
  FROM locations
  WHERE to_tsvector('english', name || ' ' || description || ' ' || array_to_string(ARRAY(SELECT jsonb_array_elements_text(tags)), ' '))
        @@ plainto_tsquery('english', search_query)
     OR name ILIKE '%' || search_query || '%'
     OR description ILIKE '%' || search_query || '%'
  ORDER BY rating DESC;
$$;
```

### `get_location_with_stats(location_id UUID)`
**Returns**: Single location with fresh aggregated stats
```sql
CREATE OR REPLACE FUNCTION get_location_with_stats(location_id UUID)
RETURNS locations
LANGUAGE sql STABLE
AS $$
  SELECT l.*
  FROM locations l
  WHERE l.id = location_id;
$$;
```

---

## Storage Buckets

### `location-photos`
- **Purpose**: All location-related photos (main photos, review photos, community photos)
- **Access**: Public read, authenticated write
- **Max file size**: 5MB
- **Allowed types**: image/jpeg, image/png, image/webp

### `avatars`
- **Purpose**: User profile pictures
- **Access**: Public read, authenticated write (only own folder: `{user_id}/*`)
- **Max file size**: 2MB
- **Allowed types**: image/jpeg, image/png, image/webp

---

## Seed Data Plan

For initial development and testing:
- **30-50 locations** across all 6 categories from real Bacolod spots
- **10+ hidden gems** with is_hidden_gem = true
- **5-10 sample reviews** on popular locations
- **Photos** — use placeholder images initially, replace with real photos later
- Categories distribution: ~10 food, ~8 coffee, ~5 nature, ~5 nightlife, ~4 arts, ~8 activities

---

## Migration Order

1. Enable extensions: `uuid-ossp`, `postgis`, `pg_trgm`
2. Create `profiles` table + auth trigger
3. Create `locations` table + indexes
4. Create `reviews` table + triggers
5. Create `check_ins` table + triggers
6. Create `favorites` table
7. Create `suggestions` table
8. Create `location_photos` table
9. Create RPC functions
10. Enable RLS on all tables + create policies
11. Create storage buckets + policies
12. Run seed data

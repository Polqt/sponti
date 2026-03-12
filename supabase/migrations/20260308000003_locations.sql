-- Migration: Create locations table
-- Column names and types match LocationModel.fromJson exactly.

CREATE TABLE public.locations (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name               TEXT NOT NULL,
  description        TEXT NOT NULL DEFAULT '',
  category           TEXT NOT NULL DEFAULT 'food'
                       CHECK (category IN ('food','coffee','nature','nightlife','arts','activities')),
  latitude           DOUBLE PRECISION NOT NULL,
  longitude          DOUBLE PRECISION NOT NULL,
  address            TEXT NOT NULL DEFAULT '',
  landmark           TEXT,
  price_range        TEXT NOT NULL DEFAULT 'budget'
                       CHECK (price_range IN ('free','budget','moderate','expensive')),
  photos             JSONB NOT NULL DEFAULT '[]'::jsonb,
  tags               JSONB NOT NULL DEFAULT '[]'::jsonb,
  rating             DOUBLE PRECISION NOT NULL DEFAULT 0.0,
  review_count       INTEGER NOT NULL DEFAULT 0,
  check_in_count     INTEGER NOT NULL DEFAULT 0,
  is_hidden_gem      BOOLEAN NOT NULL DEFAULT false,
  is_verified        BOOLEAN NOT NULL DEFAULT false,
  has_wifi           BOOLEAN NOT NULL DEFAULT false,
  is_pet_friendly    BOOLEAN NOT NULL DEFAULT false,
  has_parking        BOOLEAN NOT NULL DEFAULT false,
  open_time          TEXT,
  close_time         TEXT,
  days_open          JSONB DEFAULT '[]'::jsonb,
  special_hours_note TEXT,
  contact_number     TEXT,
  website_url        TEXT,
  instagram_handle   TEXT,
  submitted_by       UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_locations_category   ON public.locations(category);
CREATE INDEX idx_locations_rating     ON public.locations(rating DESC);
CREATE INDEX idx_locations_created    ON public.locations(created_at DESC);
CREATE INDEX idx_locations_hidden_gem ON public.locations(is_hidden_gem) WHERE is_hidden_gem = true;

ALTER TABLE public.locations
  ADD COLUMN fts tsvector
  GENERATED ALWAYS AS (
    to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(address, ''))
  ) STORED;

CREATE INDEX idx_locations_fts ON public.locations USING gin(fts);

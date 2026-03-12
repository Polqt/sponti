-- Migration: Create dependent tables (reviews, check_ins, favorites, suggestions, location_photos)
-- All reference profiles(id) and locations(id).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE public.reviews (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id  UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating       INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment      TEXT NOT NULL DEFAULT '',
  photos       JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now(),
  UNIQUE(location_id, user_id)
);

CREATE INDEX idx_reviews_location ON public.reviews(location_id);
CREATE INDEX idx_reviews_user     ON public.reviews(user_id);

CREATE TABLE public.check_ins (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id  UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  note         TEXT DEFAULT '',
  photo_url    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_checkins_location ON public.check_ins(location_id);
CREATE INDEX idx_checkins_user     ON public.check_ins(user_id);
CREATE INDEX idx_checkins_created  ON public.check_ins(created_at DESC);

CREATE TABLE public.favorites (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id  UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(location_id, user_id)
);

CREATE INDEX idx_favorites_user ON public.favorites(user_id);

CREATE TABLE public.suggestions (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  description  TEXT DEFAULT '',
  category     TEXT NOT NULL CHECK (category IN ('food','coffee','nature','nightlife','arts','activities')),
  address      TEXT DEFAULT '',
  latitude     DOUBLE PRECISION,
  longitude    DOUBLE PRECISION,
  reason       TEXT DEFAULT '',
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_suggestions_user   ON public.suggestions(user_id);
CREATE INDEX idx_suggestions_status ON public.suggestions(status);

CREATE TABLE public.location_photos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_id  UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  photo_url    TEXT NOT NULL,
  caption      TEXT DEFAULT '',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_location_photos_location ON public.location_photos(location_id);

-- Migration: Enable RLS and create policies for all tables

-- ENABLE RLS 
ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.locations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suggestions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_photos  ENABLE ROW LEVEL SECURITY;

-- PROFILES 
-- Public read (anyone can see profiles), private write (own profile only)
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- LOCATIONS 
-- Public read, authenticated create, owner update/delete
CREATE POLICY "Locations are viewable by everyone"
  ON public.locations FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create locations"
  ON public.locations FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can update own submitted locations"
  ON public.locations FOR UPDATE
  USING (auth.uid() = submitted_by);

CREATE POLICY "Users can delete own submitted locations"
  ON public.locations FOR DELETE
  USING (auth.uid() = submitted_by);

-- REVIEWS 
-- Public read (community reviews), private write (own reviews only)
CREATE POLICY "Reviews are viewable by everyone"
  ON public.reviews FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reviews"
  ON public.reviews FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reviews"
  ON public.reviews FOR DELETE
  USING (auth.uid() = user_id);

-- CHECK-INS 
-- Public read, private write
CREATE POLICY "Check-ins are viewable by everyone"
  ON public.check_ins FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create check-ins"
  ON public.check_ins FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own check-ins"
  ON public.check_ins FOR DELETE
  USING (auth.uid() = user_id);

-- FAVORITES 
-- PRIVATE: users can only see/manage their own favorites
CREATE POLICY "Users can view own favorites"
  ON public.favorites FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own favorites"
  ON public.favorites FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own favorites"
  ON public.favorites FOR DELETE
  USING (auth.uid() = user_id);

-- SUGGESTIONS
-- Users can only see their own and create new ones
CREATE POLICY "Users can view own suggestions"
  ON public.suggestions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can create suggestions"
  ON public.suggestions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- LOCATION PHOTOS 
-- Public read, authenticated create, own delete
CREATE POLICY "Location photos are viewable by everyone"
  ON public.location_photos FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can upload photos"
  ON public.location_photos FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own photos"
  ON public.location_photos FOR DELETE
  USING (auth.uid() = user_id);

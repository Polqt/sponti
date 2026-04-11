-- Run once in Supabase Dashboard → SQL Editor if you see:
-- "Could not find the 'location_id' column of 'suggestions' in the schema cache"
-- (means this migration was not applied to the linked remote yet.)
-- Equivalent to: supabase/migrations/20260411000000_suggestions_location_id_and_rls.sql

ALTER TABLE public.suggestions
  ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_suggestions_location_id
  ON public.suggestions (location_id)
  WHERE location_id IS NOT NULL;

DROP POLICY IF EXISTS "Users can update own suggestions" ON public.suggestions;
CREATE POLICY "Users can update own suggestions"
  ON public.suggestions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own suggestions" ON public.suggestions;
CREATE POLICY "Users can delete own suggestions"
  ON public.suggestions FOR DELETE
  USING (auth.uid() = user_id);

NOTIFY pgrst, 'reload schema';

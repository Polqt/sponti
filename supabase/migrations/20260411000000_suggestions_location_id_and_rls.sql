-- Link community suggestions to published locations; enable owner UPDATE/DELETE on suggestions.
-- Depends on public.suggestions and public.locations from 20260308000004_dependent_tables.sql and
-- 20260308000003_locations.sql.

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

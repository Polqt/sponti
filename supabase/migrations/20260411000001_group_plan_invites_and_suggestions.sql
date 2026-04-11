ALTER TABLE public.plan_participants
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending'
  CHECK (status IN ('pending', 'accepted', 'declined')),
ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ;

UPDATE public.plan_participants
SET status = 'accepted'
WHERE status IS DISTINCT FROM 'accepted';

CREATE TABLE IF NOT EXISTS public.plan_location_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.group_plans(id) ON DELETE CASCADE,
  location_id UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  suggested_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  suggested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(plan_id, location_id)
);

CREATE INDEX IF NOT EXISTS idx_plan_location_suggestions_plan
  ON public.plan_location_suggestions(plan_id);
CREATE INDEX IF NOT EXISTS idx_plan_location_suggestions_suggested_by
  ON public.plan_location_suggestions(suggested_by);

INSERT INTO public.plan_location_suggestions (plan_id, location_id, suggested_by, suggested_at)
SELECT DISTINCT ON (plan_id, location_id)
  plan_id,
  location_id,
  user_id,
  voted_at
FROM public.plan_votes
ON CONFLICT (plan_id, location_id) DO NOTHING;

ALTER TABLE public.plan_location_suggestions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.is_plan_creator(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_plans
    WHERE id = p_plan_id AND created_by = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_plan_invited(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.plan_participants
    WHERE plan_id = p_plan_id AND user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_plan_active_participant(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.plan_participants
    WHERE plan_id = p_plan_id
      AND user_id = p_user_id
      AND status = 'accepted'
  );
$$;

CREATE OR REPLACE FUNCTION public.can_participate_in_plan(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_plan_creator(p_plan_id, p_user_id)
    OR public.is_plan_active_participant(p_plan_id, p_user_id);
$$;

DROP POLICY IF EXISTS "group_plans_select" ON public.group_plans;
DROP POLICY IF EXISTS "plan_participants_select" ON public.plan_participants;
DROP POLICY IF EXISTS "plan_participants_insert" ON public.plan_participants;
DROP POLICY IF EXISTS "plan_participants_update" ON public.plan_participants;
DROP POLICY IF EXISTS "plan_participants_delete" ON public.plan_participants;
DROP POLICY IF EXISTS "plan_votes_select" ON public.plan_votes;
DROP POLICY IF EXISTS "plan_votes_insert" ON public.plan_votes;
DROP POLICY IF EXISTS "plan_votes_update" ON public.plan_votes;
DROP POLICY IF EXISTS "plan_votes_delete" ON public.plan_votes;
DROP POLICY IF EXISTS "plan_location_suggestions_select" ON public.plan_location_suggestions;
DROP POLICY IF EXISTS "plan_location_suggestions_insert" ON public.plan_location_suggestions;
DROP POLICY IF EXISTS "plan_location_suggestions_update" ON public.plan_location_suggestions;
DROP POLICY IF EXISTS "plan_location_suggestions_delete" ON public.plan_location_suggestions;

CREATE POLICY "group_plans_select" ON public.group_plans
  FOR SELECT USING (
    auth.uid() = created_by
    OR public.is_plan_invited(id, auth.uid())
  );

CREATE POLICY "plan_participants_select" ON public.plan_participants
  FOR SELECT USING (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
    OR public.is_plan_active_participant(plan_id, auth.uid())
  );

CREATE POLICY "plan_participants_insert" ON public.plan_participants
  FOR INSERT WITH CHECK (
    public.is_plan_creator(plan_id, auth.uid())
  );

CREATE POLICY "plan_participants_update" ON public.plan_participants
  FOR UPDATE USING (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  )
  WITH CHECK (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  );

CREATE POLICY "plan_participants_delete" ON public.plan_participants
  FOR DELETE USING (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  );

CREATE POLICY "plan_location_suggestions_select" ON public.plan_location_suggestions
  FOR SELECT USING (
    public.can_participate_in_plan(plan_id, auth.uid())
  );

CREATE POLICY "plan_location_suggestions_insert" ON public.plan_location_suggestions
  FOR INSERT WITH CHECK (
    auth.uid() = suggested_by
    AND public.can_participate_in_plan(plan_id, auth.uid())
  );

CREATE POLICY "plan_location_suggestions_update" ON public.plan_location_suggestions
  FOR UPDATE USING (
    auth.uid() = suggested_by
    OR public.is_plan_creator(plan_id, auth.uid())
  )
  WITH CHECK (
    auth.uid() = suggested_by
    OR public.is_plan_creator(plan_id, auth.uid())
  );

CREATE POLICY "plan_location_suggestions_delete" ON public.plan_location_suggestions
  FOR DELETE USING (
    auth.uid() = suggested_by
    OR public.is_plan_creator(plan_id, auth.uid())
  );

CREATE POLICY "plan_votes_select" ON public.plan_votes
  FOR SELECT USING (
    public.can_participate_in_plan(plan_id, auth.uid())
  );

CREATE POLICY "plan_votes_insert" ON public.plan_votes
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND public.can_participate_in_plan(plan_id, auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.plan_location_suggestions suggestions
      WHERE suggestions.plan_id = plan_votes.plan_id
        AND suggestions.location_id = plan_votes.location_id
    )
  );

CREATE POLICY "plan_votes_update" ON public.plan_votes
  FOR UPDATE USING (
    auth.uid() = user_id
    AND public.can_participate_in_plan(plan_id, auth.uid())
  )
  WITH CHECK (
    auth.uid() = user_id
    AND public.can_participate_in_plan(plan_id, auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.plan_location_suggestions suggestions
      WHERE suggestions.plan_id = plan_votes.plan_id
        AND suggestions.location_id = plan_votes.location_id
    )
  );

CREATE POLICY "plan_votes_delete" ON public.plan_votes
  FOR DELETE USING (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  );

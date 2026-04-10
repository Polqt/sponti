-- Fix v2: break ALL cross-table RLS recursion using security definer functions.
--
-- The cycle is:
--   group_plans SELECT policy  → queries plan_participants
--   plan_participants SELECT policy → queries group_plans (or itself via self-join)
--
-- Solution: replace all subquery-based policies with SECURITY DEFINER helper
-- functions that execute with elevated privileges and bypass RLS, breaking
-- the recursive loop entirely.

-- ── Helper functions (SECURITY DEFINER = bypass RLS inside) ─────────────────

CREATE OR REPLACE FUNCTION public.is_plan_participant(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.plan_participants
    WHERE plan_id = p_plan_id AND user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_plan_creator(p_plan_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_plans
    WHERE id = p_plan_id AND created_by = p_user_id
  );
$$;

-- ── Re-create group_plans policies (no subqueries into plan_participants) ────

DROP POLICY IF EXISTS "group_plans_select" ON public.group_plans;

CREATE POLICY "group_plans_select" ON public.group_plans
  FOR SELECT USING (
    auth.uid() = created_by
    OR public.is_plan_participant(id, auth.uid())
  );

-- ── Re-create plan_participants policies (no subqueries into group_plans) ────

DROP POLICY IF EXISTS "plan_participants_select" ON public.plan_participants;

CREATE POLICY "plan_participants_select" ON public.plan_participants
  FOR SELECT USING (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  );

DROP POLICY IF EXISTS "plan_participants_insert" ON public.plan_participants;

CREATE POLICY "plan_participants_insert" ON public.plan_participants
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    OR public.is_plan_creator(plan_id, auth.uid())
  );

-- ── Re-create plan_votes policies ────────────────────────────────────────────

DROP POLICY IF EXISTS "plan_votes_select" ON public.plan_votes;

CREATE POLICY "plan_votes_select" ON public.plan_votes
  FOR SELECT USING (
    public.is_plan_participant(plan_id, auth.uid())
    OR public.is_plan_creator(plan_id, auth.uid())
  );

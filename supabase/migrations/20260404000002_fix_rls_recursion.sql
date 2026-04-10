-- Fix infinite recursion in RLS policies for plan_participants and plan_votes.
--
-- Root cause: plan_participants_select queried group_plans which queried
-- plan_participants again (via group_plans_select), causing infinite recursion.
--
-- Fix: break the cycle by using direct column checks instead of cross-table EXISTS.

-- Drop the recursive policies
DROP POLICY IF EXISTS "plan_participants_select" ON public.plan_participants;
DROP POLICY IF EXISTS "plan_votes_select" ON public.plan_votes;

-- plan_participants: a user can see any row where they are the participant,
-- OR they are the creator of the plan (checked directly, no sub-select on plan_participants).
CREATE POLICY "plan_participants_select" ON public.plan_participants
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.group_plans gp
      WHERE gp.id = plan_id AND gp.created_by = auth.uid()
    )
  );

-- plan_votes: a user can see votes for plans they created or participate in.
-- Use plan_participants with the non-recursive column check (user_id = auth.uid())
-- to avoid going back through the group_plans → plan_participants cycle.
CREATE POLICY "plan_votes_select" ON public.plan_votes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.plan_participants pp
      WHERE pp.plan_id = plan_id AND pp.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.group_plans gp
      WHERE gp.id = plan_id AND gp.created_by = auth.uid()
    )
  );

-- Migration: Create group_plans and plan_votes tables for collaborative location voting

CREATE TABLE public.group_plans (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  description  TEXT DEFAULT '',
  created_by   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status       TEXT NOT NULL DEFAULT 'voting' CHECK (status IN ('voting', 'decided', 'cancelled')),
  winning_location_id  UUID REFERENCES public.locations(id) ON DELETE SET NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_group_plans_created_by ON public.group_plans(created_by);
CREATE INDEX idx_group_plans_status ON public.group_plans(status);
CREATE INDEX idx_group_plans_created_at ON public.group_plans(created_at DESC);

CREATE TABLE public.plan_participants (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id      UUID NOT NULL REFERENCES public.group_plans(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(plan_id, user_id)
);

CREATE INDEX idx_plan_participants_plan ON public.plan_participants(plan_id);
CREATE INDEX idx_plan_participants_user ON public.plan_participants(user_id);

CREATE TABLE public.plan_votes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id      UUID NOT NULL REFERENCES public.group_plans(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  location_id  UUID NOT NULL REFERENCES public.locations(id) ON DELETE CASCADE,
  voted_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(plan_id, user_id)
);

CREATE INDEX idx_plan_votes_plan ON public.plan_votes(plan_id);
CREATE INDEX idx_plan_votes_user ON public.plan_votes(user_id);
CREATE INDEX idx_plan_votes_location ON public.plan_votes(location_id);

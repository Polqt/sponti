-- Migration: friends system (friend_requests + friend_connections)
-- Mutual friendship model:
--   1. User A sends a request  → friend_requests row (status=pending)
--   2. User B accepts          → trigger creates TWO friend_connections rows (A→B, B→A)
--   3. Either user removes     → both connection rows deleted via trigger

-- ── 1. friend_requests ───────────────────────────────────────────────────────

CREATE TABLE public.friend_requests (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status       TEXT        NOT NULL DEFAULT 'pending'
                           CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT friend_requests_no_self_request CHECK (sender_id <> receiver_id),
  CONSTRAINT friend_requests_unique_pair     UNIQUE (sender_id, receiver_id)
);

CREATE INDEX idx_friend_requests_receiver ON public.friend_requests (receiver_id, status);
CREATE INDEX idx_friend_requests_sender   ON public.friend_requests (sender_id, status);

-- ── 2. friend_connections ────────────────────────────────────────────────────

CREATE TABLE public.friend_connections (
  user_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, friend_id),
  CONSTRAINT friend_connections_no_self CHECK (user_id <> friend_id)
);

CREATE INDEX idx_friend_connections_user   ON public.friend_connections (user_id);
CREATE INDEX idx_friend_connections_friend ON public.friend_connections (friend_id);

-- ── 3. Trigger: accept request → create both connection rows ─────────────────

CREATE OR REPLACE FUNCTION public.handle_friend_request_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    INSERT INTO public.friend_connections (user_id, friend_id)
    VALUES (NEW.sender_id, NEW.receiver_id),
           (NEW.receiver_id, NEW.sender_id)
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_friend_request_accepted
  AFTER UPDATE ON public.friend_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_friend_request_accepted();

-- ── 4. Trigger: delete connection → delete both directions ───────────────────

CREATE OR REPLACE FUNCTION public.handle_friend_connection_deleted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.friend_connections
  WHERE (user_id = OLD.user_id   AND friend_id = OLD.friend_id)
     OR (user_id = OLD.friend_id AND friend_id = OLD.user_id);
  RETURN OLD;
END;
$$;

CREATE TRIGGER on_friend_connection_deleted
  BEFORE DELETE ON public.friend_connections
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_friend_connection_deleted();

-- ── 5. RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE public.friend_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_connections ENABLE ROW LEVEL SECURITY;

-- friend_requests: sender and receiver can read their own rows
CREATE POLICY "friend_requests_select" ON public.friend_requests
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = receiver_id
  );

-- Only the sender can insert a pending request
CREATE POLICY "friend_requests_insert" ON public.friend_requests
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND status = 'pending'
  );

-- Only the receiver can update status (accept / decline)
-- Sender can also update to soft-cancel by deleting instead
CREATE POLICY "friend_requests_update" ON public.friend_requests
  FOR UPDATE USING (auth.uid() = receiver_id)
  WITH CHECK (status IN ('accepted', 'declined'));

-- Sender can cancel (delete) their own pending request
CREATE POLICY "friend_requests_delete" ON public.friend_requests
  FOR DELETE USING (auth.uid() = sender_id);

-- friend_connections: each user can see only their own side
CREATE POLICY "friend_connections_select" ON public.friend_connections
  FOR SELECT USING (auth.uid() = user_id);

-- Connections are only created via the trigger (SECURITY DEFINER) — no direct insert
-- But we allow delete so a user can remove a friend
CREATE POLICY "friend_connections_delete" ON public.friend_connections
  FOR DELETE USING (auth.uid() = user_id);

-- ── 6. Grants ─────────────────────────────────────────────────────────────────

GRANT SELECT, INSERT, UPDATE, DELETE ON public.friend_requests    TO authenticated;
GRANT SELECT, DELETE                  ON public.friend_connections TO authenticated;

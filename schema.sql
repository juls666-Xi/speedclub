-- ============================================================
-- DuelGap - Supabase PostgreSQL Schema
-- ============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";    -- for GPS distance math
CREATE EXTENSION IF NOT EXISTS "pg_cron";    -- for scheduled jobs

-- ============================================================
-- USERS TABLE (extends Supabase auth.users)
-- ============================================================
CREATE TABLE public.users (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username       TEXT UNIQUE NOT NULL CHECK (length(username) BETWEEN 3 AND 24 AND username ~ '^[a-zA-Z0-9_]+$'),
  password_hash  TEXT NOT NULL,
  created_at     TIMESTAMPTZ DEFAULT now(),
  last_seen      TIMESTAMPTZ DEFAULT now(),
  is_banned      BOOLEAN DEFAULT FALSE,
  ban_reason     TEXT,
  is_admin       BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- PROFILES TABLE
-- ============================================================
CREATE TABLE public.profiles (
  id               UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  avatar_url       TEXT,
  bio              TEXT CHECK (length(bio) <= 160),
  favorite_category TEXT CHECK (favorite_category IN ('car','bicycle','motorcycle','running')),
  total_wins       INTEGER DEFAULT 0,
  total_losses     INTEGER DEFAULT 0,
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- RANKINGS TABLE  (one row per user per category)
-- ============================================================
CREATE TYPE rank_tier AS ENUM ('bronze','silver','gold','platinum','diamond','elite','legend');

CREATE TABLE public.rankings (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category   TEXT NOT NULL CHECK (category IN ('car','bicycle','motorcycle','running')),
  rank_points INTEGER DEFAULT 1000,
  tier        rank_tier DEFAULT 'bronze',
  wins        INTEGER DEFAULT 0,
  losses      INTEGER DEFAULT 0,
  win_streak  INTEGER DEFAULT 0,
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, category)
);

-- ============================================================
-- CHALLENGES TABLE
-- ============================================================
CREATE TYPE challenge_status AS ENUM ('pending','accepted','declined','cancelled','completed','expired');

CREATE TABLE public.challenges (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenger_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  opponent_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category         TEXT NOT NULL CHECK (category IN ('car','bicycle','motorcycle','running')),
  gap_distance_m   INTEGER NOT NULL CHECK (gap_distance_m > 0),
  scheduled_at     TIMESTAMPTZ NOT NULL,
  meet_lat         DOUBLE PRECISION NOT NULL,
  meet_lng         DOUBLE PRECISION NOT NULL,
  meet_place_name  TEXT,
  optional_message TEXT,
  status           challenge_status DEFAULT 'pending',
  created_at       TIMESTAMPTZ DEFAULT now(),
  responded_at     TIMESTAMPTZ,
  CHECK (challenger_id <> opponent_id)
);

-- ============================================================
-- MATCHES TABLE
-- ============================================================
CREATE TYPE match_status AS ENUM ('lobby','waiting_gps','active','finished','cancelled','disputed');

CREATE TABLE public.matches (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  challenge_id      UUID REFERENCES public.challenges(id),
  player_a_id       UUID NOT NULL REFERENCES public.users(id),
  player_b_id       UUID NOT NULL REFERENCES public.users(id),
  category          TEXT NOT NULL CHECK (category IN ('car','bicycle','motorcycle','running')),
  gap_distance_m    INTEGER NOT NULL,
  meet_lat          DOUBLE PRECISION NOT NULL,
  meet_lng          DOUBLE PRECISION NOT NULL,
  status            match_status DEFAULT 'lobby',
  winner_id         UUID REFERENCES public.users(id),
  start_time        TIMESTAMPTZ,
  end_time          TIMESTAMPTZ,
  player_a_ready    BOOLEAN DEFAULT FALSE,
  player_b_ready    BOOLEAN DEFAULT FALSE,
  player_a_in_zone  BOOLEAN DEFAULT FALSE,
  player_b_in_zone  BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- LIVE LOCATIONS TABLE  (realtime GPS pings during race)
-- ============================================================
CREATE TABLE public.live_locations (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id       UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  lat            DOUBLE PRECISION NOT NULL,
  lng            DOUBLE PRECISION NOT NULL,
  speed_kmh      DOUBLE PRECISION DEFAULT 0,
  heading        DOUBLE PRECISION DEFAULT 0,
  accuracy_m     DOUBLE PRECISION,
  progress_m     DOUBLE PRECISION DEFAULT 0,   -- distance traveled from start
  recorded_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (match_id, user_id)                   -- upsert latest position
);

-- Archive table for post-race route replay
CREATE TABLE public.location_history (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id       UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  lat            DOUBLE PRECISION NOT NULL,
  lng            DOUBLE PRECISION NOT NULL,
  speed_kmh      DOUBLE PRECISION DEFAULT 0,
  progress_m     DOUBLE PRECISION DEFAULT 0,
  recorded_at    TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- MATCH HISTORY TABLE  (summary after race ends)
-- ============================================================
CREATE TABLE public.match_history (
  id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id            UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  user_id             UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  opponent_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  category            TEXT NOT NULL,
  result              TEXT NOT NULL CHECK (result IN ('win','loss')),
  top_speed_kmh       DOUBLE PRECISION,
  total_distance_m    DOUBLE PRECISION,
  race_duration_s     INTEGER,
  max_lead_m          DOUBLE PRECISION,
  rank_points_delta   INTEGER,
  rank_before         INTEGER,
  rank_after          INTEGER,
  played_at           TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- NOTIFICATIONS TABLE
-- ============================================================
CREATE TYPE notif_type AS ENUM (
  'challenge_received','challenge_accepted','challenge_declined',
  'match_starting_soon','opponent_arrived','race_complete',
  'rank_up','rank_down','system'
);

CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        notif_type NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  data        JSONB,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- FCM TOKENS TABLE
-- ============================================================
CREATE TABLE public.fcm_tokens (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token      TEXT NOT NULL UNIQUE,
  platform   TEXT CHECK (platform IN ('android','ios')),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- REPORTS TABLE  (admin moderation)
-- ============================================================
CREATE TYPE report_status AS ENUM ('open','reviewed','resolved','dismissed');

CREATE TABLE public.reports (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id   UUID NOT NULL REFERENCES public.users(id),
  reported_id   UUID NOT NULL REFERENCES public.users(id),
  match_id      UUID REFERENCES public.matches(id),
  reason        TEXT NOT NULL,
  details       TEXT,
  status        report_status DEFAULT 'open',
  admin_notes   TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  resolved_at   TIMESTAMPTZ
);

-- ============================================================
-- GPS ANOMALY LOG  (admin cheat detection)
-- ============================================================
CREATE TABLE public.gps_anomalies (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id    UUID NOT NULL REFERENCES public.matches(id),
  user_id     UUID NOT NULL REFERENCES public.users(id),
  anomaly_type TEXT NOT NULL, -- 'speed_spike','teleport','mock_location'
  details     JSONB,
  detected_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- MATCHMAKING QUEUE TABLE
-- ============================================================
CREATE TABLE public.matchmaking_queue (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  category     TEXT NOT NULL CHECK (category IN ('car','bicycle','motorcycle','running')),
  rank_points  INTEGER NOT NULL,
  lat          DOUBLE PRECISION,
  lng          DOUBLE PRECISION,
  queued_at    TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_challenges_opponent    ON public.challenges(opponent_id, status);
CREATE INDEX idx_challenges_challenger  ON public.challenges(challenger_id, status);
CREATE INDEX idx_matches_players        ON public.matches(player_a_id, player_b_id);
CREATE INDEX idx_live_locations_match   ON public.live_locations(match_id);
CREATE INDEX idx_notif_user_unread      ON public.notifications(user_id, is_read);
CREATE INDEX idx_match_history_user     ON public.match_history(user_id, played_at DESC);
CREATE INDEX idx_rankings_category      ON public.rankings(category, rank_points DESC);
CREATE INDEX idx_mmq_category_rank      ON public.matchmaking_queue(category, rank_points);

-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Auto-update rank tier based on points
CREATE OR REPLACE FUNCTION update_rank_tier()
RETURNS TRIGGER AS $$
BEGIN
  NEW.tier := CASE
    WHEN NEW.rank_points >= 5000 THEN 'legend'
    WHEN NEW.rank_points >= 3500 THEN 'elite'
    WHEN NEW.rank_points >= 2500 THEN 'diamond'
    WHEN NEW.rank_points >= 1800 THEN 'platinum'
    WHEN NEW.rank_points >= 1200 THEN 'gold'
    WHEN NEW.rank_points >= 600  THEN 'silver'
    ELSE 'bronze'
  END::rank_tier;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_rank_tier
  BEFORE UPDATE OF rank_points ON public.rankings
  FOR EACH ROW EXECUTE FUNCTION update_rank_tier();

-- Auto-create profile & rankings on user insert
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles(id) VALUES (NEW.id);
  INSERT INTO public.rankings(user_id, category) VALUES
    (NEW.id, 'car'),
    (NEW.id, 'bicycle'),
    (NEW.id, 'motorcycle'),
    (NEW.id, 'running');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_new_user
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Haversine distance helper (meters)
CREATE OR REPLACE FUNCTION haversine_m(
  lat1 DOUBLE PRECISION, lng1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION, lng2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
  R CONSTANT DOUBLE PRECISION := 6371000;
  dlat DOUBLE PRECISION := radians(lat2 - lat1);
  dlng DOUBLE PRECISION := radians(lng2 - lng1);
  a DOUBLE PRECISION;
BEGIN
  a := sin(dlat/2)^2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng/2)^2;
  RETURN R * 2 * asin(sqrt(a));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Check win condition (called by server-side function / edge function)
CREATE OR REPLACE FUNCTION check_win_condition(p_match_id UUID)
RETURNS TABLE(winner_id UUID, gap_m DOUBLE PRECISION) AS $$
DECLARE
  rec RECORD;
  gap DOUBLE PRECISION;
  req DOUBLE PRECISION;
BEGIN
  SELECT m.player_a_id, m.player_b_id, m.gap_distance_m,
         la.progress_m AS a_prog, lb.progress_m AS b_prog
  INTO rec
  FROM public.matches m
  LEFT JOIN public.live_locations la ON la.match_id = m.id AND la.user_id = m.player_a_id
  LEFT JOIN public.live_locations lb ON lb.match_id = m.id AND lb.user_id = m.player_b_id
  WHERE m.id = p_match_id AND m.status = 'active';

  IF NOT FOUND THEN RETURN; END IF;

  req := rec.gap_distance_m;

  -- A leads
  gap := COALESCE(rec.a_prog, 0) - COALESCE(rec.b_prog, 0);
  IF gap >= req THEN
    winner_id := rec.player_a_id; gap_m := gap; RETURN NEXT;
    RETURN;
  END IF;

  -- B leads
  gap := COALESCE(rec.b_prog, 0) - COALESCE(rec.a_prog, 0);
  IF gap >= req THEN
    winner_id := rec.player_b_id; gap_m := gap; RETURN NEXT;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Award rank points after match
CREATE OR REPLACE FUNCTION award_rank_points(
  p_winner_id UUID, p_loser_id UUID, p_category TEXT,
  p_winner_pts INTEGER DEFAULT 30, p_loser_pts INTEGER DEFAULT -15
) RETURNS VOID AS $$
BEGIN
  UPDATE public.rankings
  SET rank_points = GREATEST(0, rank_points + p_winner_pts),
      wins        = wins + 1,
      win_streak  = win_streak + 1
  WHERE user_id = p_winner_id AND category = p_category;

  UPDATE public.rankings
  SET rank_points = GREATEST(0, rank_points + p_loser_pts),
      losses      = losses + 1,
      win_streak  = 0
  WHERE user_id = p_loser_id AND category = p_category;

  UPDATE public.profiles SET total_wins = total_wins + 1 WHERE id = p_winner_id;
  UPDATE public.profiles SET total_losses = total_losses + 1 WHERE id = p_loser_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.users             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rankings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.live_locations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_history  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_history     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_anomalies     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matchmaking_queue ENABLE ROW LEVEL SECURITY;

-- Helper: get current user id from JWT
CREATE OR REPLACE FUNCTION auth_uid() RETURNS UUID AS $$
  SELECT (current_setting('request.jwt.claims', TRUE)::jsonb->>'sub')::UUID;
$$ LANGUAGE sql STABLE;

-- Users: read public, write own
CREATE POLICY users_read      ON public.users FOR SELECT USING (TRUE);
CREATE POLICY users_update    ON public.users FOR UPDATE USING (id = auth_uid());

-- Profiles: read all, write own
CREATE POLICY profiles_read   ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY profiles_write  ON public.profiles FOR ALL USING (id = auth_uid());

-- Rankings: read all, write own
CREATE POLICY rankings_read   ON public.rankings FOR SELECT USING (TRUE);
CREATE POLICY rankings_write  ON public.rankings FOR UPDATE USING (user_id = auth_uid());

-- Challenges: read own, write as challenger
CREATE POLICY challenges_read    ON public.challenges FOR SELECT
  USING (challenger_id = auth_uid() OR opponent_id = auth_uid());
CREATE POLICY challenges_insert  ON public.challenges FOR INSERT
  WITH CHECK (challenger_id = auth_uid());
CREATE POLICY challenges_update  ON public.challenges FOR UPDATE
  USING (challenger_id = auth_uid() OR opponent_id = auth_uid());

-- Matches: read if participant
CREATE POLICY matches_read  ON public.matches FOR SELECT
  USING (player_a_id = auth_uid() OR player_b_id = auth_uid());
CREATE POLICY matches_write ON public.matches FOR UPDATE
  USING (player_a_id = auth_uid() OR player_b_id = auth_uid());

-- Live locations: read if in same match, write own
CREATE POLICY livepos_select ON public.live_locations FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = match_id AND (m.player_a_id = auth_uid() OR m.player_b_id = auth_uid())
  ));
CREATE POLICY livepos_upsert ON public.live_locations FOR ALL
  USING (user_id = auth_uid()) WITH CHECK (user_id = auth_uid());

-- Notifications: own only
CREATE POLICY notif_own ON public.notifications FOR ALL USING (user_id = auth_uid());

-- FCM tokens: own only
CREATE POLICY fcm_own ON public.fcm_tokens FOR ALL USING (user_id = auth_uid());

-- Match history: read own
CREATE POLICY mh_own ON public.match_history FOR SELECT USING (user_id = auth_uid());

-- Reports: read own reports
CREATE POLICY reports_own ON public.reports FOR ALL USING (reporter_id = auth_uid());

-- Matchmaking queue: own only
CREATE POLICY mmq_own ON public.matchmaking_queue FOR ALL USING (user_id = auth_uid());

-- ============================================================
-- REALTIME PUBLICATIONS
-- ============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.live_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.challenges;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.matchmaking_queue;
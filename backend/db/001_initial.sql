CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE rarity_tier AS ENUM ('frequent', 'notable', 'rare', 'exceptional', 'singular');

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  handle TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE aircraft (
  id UUID PRIMARY KEY,
  registration TEXT NOT NULL UNIQUE,
  icao24 CHAR(6) UNIQUE,
  manufacturer TEXT NOT NULL,
  model TEXT NOT NULL,
  variant TEXT,
  operator_name TEXT,
  active_livery_id UUID,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE liveries (
  id UUID PRIMARY KEY,
  operator_name TEXT NOT NULL,
  name TEXT NOT NULL,
  valid_from DATE,
  valid_to DATE,
  active_airframe_count INTEGER,
  paint_spec JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (operator_name, name, valid_from)
);

ALTER TABLE aircraft ADD CONSTRAINT aircraft_active_livery_fk
  FOREIGN KEY (active_livery_id) REFERENCES liveries(id);

CREATE TABLE radar_sessions (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  center GEOGRAPHY(POINT, 4326) NOT NULL,
  radius_meters INTEGER NOT NULL CHECK (radius_meters BETWEEN 100 AND 100000),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  collection_rules JSONB NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX radar_sessions_center_gix ON radar_sessions USING GIST(center);

CREATE TABLE encounters (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  aircraft_id UUID NOT NULL REFERENCES aircraft(id),
  radar_session_id UUID REFERENCES radar_sessions(id),
  observed_at TIMESTAMPTZ NOT NULL,
  position GEOGRAPHY(POINT, 4326) NOT NULL,
  altitude_feet INTEGER,
  flight_number TEXT,
  origin_iata CHAR(3),
  destination_iata CHAR(3),
  rarity_score SMALLINT NOT NULL CHECK (rarity_score BETWEEN 0 AND 100),
  rarity rarity_tier NOT NULL,
  rarity_factors JSONB NOT NULL,
  collected_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX encounters_user_time_idx ON encounters(user_id, observed_at DESC);
CREATE INDEX encounters_position_gix ON encounters USING GIST(position);

CREATE TABLE device_tokens (
  token TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  environment TEXT NOT NULL CHECK (environment IN ('development', 'production')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX device_tokens_user_idx ON device_tokens(user_id);

CREATE TABLE frequencies (
  id UUID PRIMARY KEY,
  channel NUMERIC(6,3) NOT NULL UNIQUE,
  name TEXT NOT NULL,
  visibility TEXT NOT NULL CHECK (visibility IN ('public', 'private', 'local')),
  created_by TEXT NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE transmissions (
  id UUID PRIMARY KEY,
  frequency_id UUID NOT NULL REFERENCES frequencies(id),
  author_id TEXT NOT NULL REFERENCES users(id),
  encounter_id UUID NOT NULL REFERENCES encounters(id),
  body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX transmissions_frequency_time_idx ON transmissions(frequency_id, created_at DESC) WHERE deleted_at IS NULL;

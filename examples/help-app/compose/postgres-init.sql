-- Schema for the help app's Postgres (runs once, when the data volume is first created).
-- Plain columns only, no GENERATED columns: a generated column breaks a Zetaris INSERT, and columns
-- left out of an INSERT arrive as NULL, not as the column default.

CREATE TABLE IF NOT EXISTS docs (
  path text PRIMARY KEY,
  corpus text,
  title text,
  kind text,
  bytes bigint,
  git_sha text,
  chunk_count integer
);

CREATE TABLE IF NOT EXISTS chunks (
  chunk_id text PRIMARY KEY,
  path text,
  part integer,
  section text,
  char_count integer,
  chunk_text text
);

-- Append-only log of pinned answers and what people did with them (Phase 6).
CREATE TABLE IF NOT EXISTS pins (
  pin_id text PRIMARY KEY,
  question text,
  answer text,
  origin text,
  model text,
  collection text,
  sources text,
  pinned_at timestamp,
  pinned_by text,
  status text
);

CREATE TABLE IF NOT EXISTS pin_events (
  event_id text PRIMARY KEY,
  pin_id text,
  kind text,
  at timestamp,
  who text
);

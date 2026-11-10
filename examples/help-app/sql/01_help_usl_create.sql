-- help_usl: the doc catalog, chunk catalog, standing search/answer relations and the pin log
-- as one Unified Semantic Layer. Run with scripts/build_usl.ts (it registers the Postgres
-- datasource `help_pg` and fills docs and chunks first); or run_sql.py after those steps.
--
-- USL rules this relies on (docs/guides/zetaris-lightning-sql-companion.md, section 8.4): scalar
-- column types only; `source` is reserved (hence `origin`); NOT NULL needs coalesce() in the
-- activation; tables are read-only; a referenced table is declared before the table that refers
-- to it; a foreign key is written `col type FOREIGN KEY REFERENCES t(col)`.
--
-- `search` and `answers` sit over the saved pipeline relations. Their question is fixed inside the
-- relation and a SELECT runs the whole pipeline (answers calls the LLM every time), so treat them
-- as standing-question tables: do not join them to anything.
-- The namespace must exist before COMPILE USL (otherwise: "namespace not found").
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.help_app_usl;

COMPILE USL IF NOT EXISTS help_usl DEPLOY NAMESPACE lightning.metastore.help_app_usl DDL
CREATE TABLE docs (
    path varchar(400) NOT NULL PRIMARY KEY,
    corpus varchar(20),
    title varchar(400),
    kind varchar(40),
    bytes bigint,
    git_sha varchar(64),
    chunk_count int
);
CREATE TABLE chunks (
    chunk_id varchar(500) NOT NULL PRIMARY KEY,
    path varchar(400) FOREIGN KEY REFERENCES docs(path),
    part int,
    section varchar(400),
    char_count int,
    chunk_text varchar(4000)
);
CREATE TABLE search (
    prompt varchar(1000),
    content varchar(4000),
    similarity double
);
CREATE TABLE answers (
    prompt varchar(1000),
    answer varchar(65535),
    contexts varchar(65535)
);
CREATE TABLE pins (
    pin_id varchar(64) NOT NULL PRIMARY KEY,
    question varchar(4000),
    answer varchar(65535),
    origin varchar(20),
    model varchar(100),
    collection varchar(100),
    sources varchar(65535),
    pinned_at timestamp,
    pinned_by varchar(100),
    status varchar(20)
);
CREATE TABLE pin_events (
    event_id varchar(64) NOT NULL PRIMARY KEY,
    pin_id varchar(64) FOREIGN KEY REFERENCES pins(pin_id),
    kind varchar(20),
    at timestamp,
    who varchar(100)
);
CREATE TABLE pin_scores (
    pin_id varchar(64) NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES pins(pin_id),
    likes int,
    uses int,
    last_event timestamp
);

UPDATE USL lightning.metastore.help_app_usl.help_usl SET DESCRIPTION 'Help app: doc catalog, chunk catalog, standing search and answer relations, pinned answers and their events';

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.docs AS
  SELECT coalesce(path, '') AS path, corpus, title, kind, bytes, git_sha, chunk_count FROM help_pg.docs;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.chunks AS
  SELECT coalesce(chunk_id, '') AS chunk_id, path, part, section, char_count, chunk_text FROM help_pg.chunks;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.search AS
  SELECT prompt, content, similarity FROM help_app.help_search;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.answers AS
  SELECT prompt, answer, concat_ws('\n---\n', contexts) AS contexts FROM help_app.help_answer;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.pins AS
  SELECT coalesce(pin_id, '') AS pin_id, question, answer, origin, model, collection, sources, pinned_at, pinned_by, status FROM help_pg.pins;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.pin_events AS
  SELECT coalesce(event_id, '') AS event_id, pin_id, kind, at, who FROM help_pg.pin_events;

ACTIVATE USL TABLE lightning.metastore.help_app_usl.help_usl.pin_scores AS
  SELECT coalesce(p.pin_id, '') AS pin_id,
         CAST(coalesce(sum(CASE WHEN e.kind = 'like' THEN 1 WHEN e.kind = 'unlike' THEN -1 ELSE 0 END), 0) AS int) AS likes,
         CAST(coalesce(sum(CASE WHEN e.kind = 'use' THEN 1 ELSE 0 END), 0) AS int) AS uses,
         max(e.at) AS last_event
  FROM help_pg.pins p LEFT JOIN help_pg.pin_events e ON e.pin_id = p.pin_id GROUP BY p.pin_id;

-- Virtual data mart over help_usl: business-style views without exposing the raw tables.
-- DESCRIBE BY allows only letters, digits and _ . - , (no other punctuation).
-- ADD DATAMART TABLE needs a VSCHEMA that lists EVERY column of the source table.
CREATE DATAMART help_mart DESCRIBE BY 'Help app doc catalog and pinned answer scores';

ADD DATAMART TABLE doc_catalog INTO help_mart FROM lightning.metastore.help_app_usl.help_usl.docs VSCHEMA (path path, corpus corpus, title title, kind kind, bytes bytes, git_sha git_sha, chunk_count chunk_count);

ADD DATAMART TABLE answer_scores INTO help_mart FROM lightning.metastore.help_app_usl.help_usl.pin_scores VSCHEMA (pin_id pin_id, likes likes, uses uses, last_event last_event);

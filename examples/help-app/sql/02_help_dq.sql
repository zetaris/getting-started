-- Data quality: one Foreign Key rule per FK column of help_usl. Form: RUN DQ <column> TABLE <namespace>.<usl>.<table>.
-- chunks.path -> docs.path is the one that matters on real data; the pins pair is empty until pins exist.
RUN DQ path TABLE lightning.metastore.help_app_usl.help_usl.chunks;
RUN DQ pin_id TABLE lightning.metastore.help_app_usl.help_usl.pin_events;
RUN DQ pin_id TABLE lightning.metastore.help_app_usl.help_usl.pin_scores;

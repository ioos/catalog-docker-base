-- A view for harvest summary statistics that's useful for monitoring
-- dashboards.
CREATE OR REPLACE VIEW harvest_view_summary AS 
WITH record_times AS (
         SELECT max(hj.finished) AS harvest_job_last_finished,
            hj.source_id
           FROM harvest_job hj
          WHERE hj.status = 'Finished'::text
          GROUP BY hj.source_id
        ), record_counts AS (
         SELECT count(*) AS total_current_recs,
            sum(
                CASE
                    WHEN harvest_object.import_finished >= (now() - '36:00:00'::interval) THEN 1
                    ELSE 0
                END) AS new_current_recs,
            harvest_object.harvest_source_id AS source_id
           FROM harvest_object
          WHERE harvest_object.current
          GROUP BY harvest_object.harvest_source_id
        )
 SELECT hs.title AS waf_name,
    date_part('epoch'::text, now() - record_times.harvest_job_last_finished::timestamp with time zone) AS harvest_finished_timedelta,
    record_counts.new_current_recs AS new_rec_count,
    record_counts.total_current_recs AS total_rec_count
   FROM harvest_source hs
     LEFT JOIN record_times ON record_times.source_id = hs.id
     LEFT JOIN record_counts ON record_counts.source_id = hs.id;

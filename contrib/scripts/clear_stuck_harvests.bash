#!/usr/bin/env bash

# Delete any harvest jobs

while IFS= read -r id; do
    ckan -c /etc/ckan/production.ini harvester job-abort "$id";
done < <(psql -h "${DB_HOST:-db}" -U ckan -qAt -c "SELECT id FROM harvest_job WHERE status = 'Running' AND created <= NOW() - '3 day'::interval")

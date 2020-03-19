#!/usr/bin/env bash

# Delete any harvest jobs

while IFS= read -r id; do
    ckan-paster --plugin=ckanext-harvest harvester \
         -c /etc/ckan/production.ini job_abort "$id";
done < <(psql -h db -U ckan -qAt -c "SELECT id FROM harvest_job WHERE status = 'Running' AND gather_started <= NOW() - '3 day'::interval")

ckan-paster --plugin=ckanext-harvest harvester -c /etc/ckan/production.ini job-all

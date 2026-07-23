#!/bin/bash
HARVEST="ckan -c /srv/app/production.ini harvester"
for source in $($HARVEST sources | grep 'Source id' | awk '{print $3}'); do
    $HARVEST clearsource "$source"
done

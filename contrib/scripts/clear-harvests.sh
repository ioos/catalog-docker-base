#!/bin/bash
HARVEST="ckan -c /etc/ckan/production.ini harvester"
for source in $($HARVEST sources | grep 'Source id' | awk '{print $3}'); do
    $HARVEST clearsource "$source"
done

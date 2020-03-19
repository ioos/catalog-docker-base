#!/bin/bash
HARVEST="$CKAN_HOME/bin/paster --plugin=ckanext-harvest harvester -c $CKAN_CONFIG/ckan.ini"
for source in $($HARVEST sources | grep 'Source id' | awk '{print $3}'); do
    $HARVEST clearsource $source
done

$HARVEST job-all


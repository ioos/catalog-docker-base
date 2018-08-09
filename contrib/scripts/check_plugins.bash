#!/bin/bash
set -e

# first load the original ckan entrypoint
# exit with true to ensure the

google_analytics_enabled=${GA_ENABLED:-}
config="/etc/ckan/production.ini"

ckan-paster --plugin=ckan config-tool "$config" \
    "googleanalytics.id=${GA_ID:-none}" \
    "googleanalytics.account=${GA_ACCOUNT:-none}" \
    "googleanalytics.username=${GA_USERNAME:-none}" \
    "googleanalytics.password=${GA_PASSWORD:-none}" \
    "googleanalytics.track_events=false"


function setup_google_analytics {
       ckan-paster --plugin=ckan config-tool "$config" \
            "googleanalytics.id=${GA_ID}" \
            "googleanalytics.account=${GA_ACCOUNT}" \
            "googleanalytics.username=${GA_USERNAME}" \
            "googleanalytics.password=${GA_PASSWORD}" \
            "googleanalytics.track_events=true"
       ckan-paster --plugin=ckanext-googleanalytics initdb -c "$config"
}

# temporarily alias exec to true so we can "extend" this entrypoint
alias exec=true
# source the original entrypoint with aliased exec
. /ckan-entrypoint.sh
unalias exec

if [[ -v POSTGRES_PASSWORD ]]; then
    export PGPASSWORD="$POSTGRES_PASSWORD"
fi
# get the original list of plugins after equals sign
# (hopefully not newline separated
plugins_orig=$(grep -Po --color '(?<=^ckan\.plugins)\s*=.*$' "$config" |\
               sed 's/^\s*=\s*//')

missing_plugins=$(comm -13 <(sort <<< "${plugins_orig// /$'\n'}") <(sort <<EOF
ioos_theme
spatial_metadata
spatial_query
harvest
ckan_harvester
csw_harvester
waf_harvester
ioos_waf
googleanalytics
EOF
) | tr "\n" ' ' | sed 's/ $//')

if [[ -n "$missing_plugins" ]]; then
    new_plugins_line="$plugins_orig $missing_plugins"

    ckan-paster --plugin=ckan config-tool "$config" -e \
                          "ckan.plugins = $new_plugins_line"
fi

#ckan-paster --plugin=ckan config-tool "$config" "ckan.tracking_enabled = true"

ckan-paster --plugin=ckan config-tool "$config" "ckan.tracking_enabled = true"
if [[ "$google_analytics_enabled" = true ]]; then
    setup_google_analytics
fi

# TODO: make sure database is running
ckan-paster --plugin=ckanext-googleanalytics initdb -c "$config"
ckan-paster --plugin=ckan db init -c "$config"
ckan-paster --plugin=ckanext-spatial spatial initdb -c "$config"
ckan-paster --plugin=ckanext-harvest harvester initdb -c "$config"

db_q="SELECT 1 FROM pg_database WHERE datname='pycsw'"
if [[ -z "$(psql -h db -tAc "$db_q")" ]]; then
   createdb -h db -U ckan pycsw -E utf-8
fi

psql -h db -U ckan -qc 'CREATE EXTENSION IF NOT EXISTS postgis' pycsw

tbl_q="SELECT 1 FROM information_schema.tables WHERE table_name = 'records'"
if [[ -z "$(psql -h db -tAc "$tbl_q" pycsw)" ]]; then
    ckan-paster --plugin=ckanext-spatial ckan-pycsw setup -p \
        /etc/pycsw/pycsw.cfg
fi

ckan-paster --plugin=ckan config-tool "$config" \
                    "ckan.base_public_folder = public-bs2" \
                    "ckan.base_templates_folder = templates-bs2" \
                    "ckan.site_title = IOOS Catalog" \
                    "ckan.site_logo = /ioos_logo.png" \
                    "ckan.harvest.mq.type = redis" \
                    "ckan.harvest.mq.hostname = redis" \
                    "ckanext.harvest.default_dataset_name_append = random-hex" \
                    "ckan.spatial.validator.profiles = iso19139ngdc" \
                    "ckanext.spatial.search_backend = solr" \
                    "ckan.spatial.harvest.continue_on_validation_errors = true"

exec "$@"

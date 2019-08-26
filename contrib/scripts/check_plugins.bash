#!/bin/bash
set -e

# first load the original ckan entrypoint
# exit with true to ensure the

google_analytics_enabled="${GA_ENABLED:-}"
pycsw_default_db="${PYCSW_DB:-pycsw}"
db_port="${POSTGRES_PORT:-5432}"
config="/etc/ckan/production.ini"

# Set default site_url
if [[ -z "$CKAN_SITE_URL" ]]; then
  CKAN_SITE_URL="http://localhost"
fi

# source the original CKAN entrypoint without the final call to exec
. <(grep -v '^exec' /ckan-entrypoint.sh)

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
dcat
dcat_rdf_harvester
dcat_json_harvester
dcat_json_interface
structured_data
sitemap
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

db_q="SELECT 1 FROM pg_database WHERE datname='$pycsw_default_db'"
if [[ -z "$(psql -h db -p "$db_port" -U ckan -tAc "$db_q")" ]]; then
   createdb -h db -p "$db_port" -U ckan "$pycsw_default_db" -E utf-8
fi

psql -h db -U ckan -p "$db_port" -qc 'CREATE EXTENSION IF NOT EXISTS postgis' "$pycsw_default_db"

# make sure /etc/pycsw/pycsw.cfg has correct DB set
tbl_q="SELECT 1 FROM information_schema.tables WHERE table_name = 'records'"
if [[ -z "$(psql -h db -p "$db_port" -U ckan -tAc "$tbl_q" \
     "$pycsw_default_db")" ]]; then
    ckan-paster --plugin=ckanext-spatial ckan-pycsw setup -p \
        /etc/pycsw/pycsw.cfg
fi

ckan-paster --plugin=ckan config-tool "$config" \
                    "ckan.site_title = IOOS Catalog" \
                    "ckan.site_logo = /ioos_logo.png" \
                    "ckan.harvest.mq.type = redis" \
                    "ckan.harvest.mq.hostname = redis" \
                    "ckan.harvest.mq.port = ${REDIS_PORT:-6379}" \
                    "ckan.spatial.validator.profiles = iso19139ngdc" \
                    "ckanext.spatial.common_map.type = custom" \
                    "ckanext.spatial.common_map.custom.url = http://services.arcgisonline.com/ArcGIS/rest/services/Ocean_Basemap/MapServer/tile/{z}/{y}/{x}" \
                    "ckanext.spatial.common_map = Esri, Garmin, GEBCO, NOAA NGDC, and other contributors" \
                    "ckanext.spatial.search_backend = solr" \
                    "ckan.spatial.harvest.continue_on_validation_errors = true" \
                    "ckan.ioos_theme.pycsw_config=/etc/pycsw/pycsw.cfg" \
                    "ckan.cors.origin_allow_all = true"

if [ -n "$MAIL_SERVER" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.server = $MAIL_SERVER"
fi
if [ -n "$MAIL_PORT" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.port = $MAIL_PORT"
fi
if [ -n "$MAIL_USE_TLS" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.starttls = $MAIL_USE_TLS"
fi
if [ -n "$MAIL_USERNAME" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.user = $MAIL_USERNAME"
fi
if [ -n "$MAIL_PASSWORD" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.password = $MAIL_PASSWORD"
fi
if [ -n "$MAIL_FROM" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "smtp.mail_from = $MAIL_FROM"
fi
if [ -n "$FEEDBACK_RECIPIENTS" ]; then
  ckan-paster --plugin=ckan config-tool "$CONFIG" "feedback.recipients = $FEEDBACK_RECIPIENTS"
fi

exec "$@"

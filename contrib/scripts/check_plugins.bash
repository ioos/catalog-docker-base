#!/usr/bin/env bash
set -x

# first load the original ckan entrypoint
# exit with true to ensure the

google_analytics_enabled=${GA_ENABLED:-}
pycsw_default_db=${PYCSW_DB:-pycsw}
if [[ $CKAN_SQLALCHEMY_URL =~ @([^/:]+) ]]; then
   db_host=${BASH_REMATCH[1]}
else
   db_host=db
fi
pycsw_default_db="${PYCSW_DB:-pycsw}"
db_port="${POSTGRES_PORT:-5432}"
config="/srv/app/production.ini"

# Set default site_url
if [[ -z "$CKAN_SITE_URL" ]]; then
  CKAN_SITE_URL="http://localhost:5000"
fi

# source the original CKAN entrypoint without the final call to exec
. <(grep -v '^exec' /ckan-entrypoint.sh)

# needed for consistent secret key?
ckan generate config "$config"
ckan config-tool "$config" \
    "googleanalytics.id=${GA_ID:-none}" \
    "googleanalytics.account=${GA_ACCOUNT:-none}" \
    "googleanalytics.username=${GA_USERNAME:-none}" \
    "googleanalytics.password=${GA_PASSWORD:-none}" \
    "googleanalytics.track_events=false"


function setup_google_analytics {
       ckan config-tool "$config" \
            "googleanalytics.id=${GA_ID}" \
            "googleanalytics.account=${GA_ACCOUNT}" \
            "googleanalytics.username=${GA_USERNAME}" \
            "googleanalytics.password=${GA_PASSWORD}" \
            "googleanalytics.track_events=true"
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
ioos_waf
spatial_metadata
spatial_query
harvest
ckan_harvester
csw_harvester
waf_harvester
dcat
googleanalytics
dcat_rdf_harvester
dcat_json_harvester
dcat_json_interface
structured_data
EOF
) | tr "\n" ' ' | sed 's/ $//')

if [[ -n "$missing_plugins" ]]; then
    new_plugins_line="$plugins_orig $missing_plugins"

    ckan config-tool "$config" -e \
                          "ckan.plugins = $new_plugins_line"
fi

ckan config-tool "$config" "ckan.tracking_enabled = true"
if [[ "$google_analytics_enabled" = true ]]; then
    setup_google_analytics
fi

# TODO: make sure database is running
check_user_query="SELECT user FROM user WHERE user = 'ckan'"
if [[ -z "$(psql -h "$db_host" -p "$db_port" -U ckan -tAc "$check_user_query" -U postgres)" ]]; then
    # Potentially could use `createuser` utility here as well
    psql -h "$db_host" -p "$db_port" -c "CREATE USER ckan WITH PASSWORD '$CKAN_DB_PASSWORD' CREATEDB" -U postgres
    # assumes DB does not also exist if ckan user does not exist
    createdb -h "$db_host" -p "$db_port" -U ckan ckan 2> /dev/null
    psql -h "$db_host" -p "$db_port" -c "CREATE EXTENSION IF NOT EXISTS postgis" ckan postgres
fi


db_q="SELECT 1 FROM pg_database WHERE datname='$pycsw_default_db'"
if [[ -z "$(psql -h "$db_host" -p "$db_port" -U ckan -tAc "$db_q")" ]]; then
   createdb -h "$db_host" -p "$db_port" -U ckan "$pycsw_default_db" -E utf-8
fi

psql -h "$db_host" -U ckan -p "$db_port" -qc 'CREATE EXTENSION IF NOT EXISTS postgis' "$pycsw_default_db"

# make sure /etc/pycsw/pycsw.cfg has correct DB set
tbl_q="SELECT 1 FROM information_schema.tables WHERE table_name = 'records'"
if [[ -z "$(psql -h "$db_host" -p "$db_port" -U ckan -tAc "$tbl_q" \
     "$pycsw_default_db")" ]]; then
    python /usr/lib/ckan/venv/src/ckanext-spatial/bin/ckan_pycsw.py -p /etc/pycsw/pycsw.cfg
    ckan -c "$config" spatial ckan_pycsw setup -p /etc/pycsw/pycsw.cfg
fi

# HACK: eliminate datastore/datapusher from config since it keeps getting added
sed -ri -e '/ckan\.data(store|pusher)/d' -e 's/data(store|pusher)//' "$config"

ckan config-tool "$config" \
                    "ckan.auth.create_user_via_api = false" \
                    "ckan.auth.create_user_via_web = false" \
                    "ckan.site_title = IOOS Catalog" \
                    "ckan.site_logo = /ioos_logo.png" \
                    "ckan.harvest.mq.type = redis" \
                    "ckan.harvest.mq.hostname = redis" \
                    "ckan.harvest.mq.port = ${REDIS_PORT:-6379}" \
                    "ckan.spatial.validator.profiles = iso19139ngdc" \
                    "ckanext.spatial.common_map.type = custom" \
                    "ckanext.spatial.common_map.custom.url = https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}" \
                    "ckanext.spatial.common_map.attribution = Esri, Garmin, GEBCO, NOAA NGDC, and other contributors" \
                    "ckanext.spatial.search_backend = solr-spatial-field" \
                    "ckan.spatial.harvest.continue_on_validation_errors = true" \
                    "ckan.ioos_theme.pycsw_config=/etc/pycsw/pycsw.cfg" \
                    "ckan.cors.origin_allow_all = true"

ckan -c "$config" db init
ckan -c "$config" spatial initdb
ckan -c "$config" harvester initdb
ckan -c "$config" db pending-migrations --apply

if [ -n "$MAIL_SERVER" ]; then
  ckan config-tool "$config" "smtp.server = $MAIL_SERVER"
fi
if [ -n "$MAIL_PORT" ]; then
  ckan config-tool "$config" "smtp.port = $MAIL_PORT"
fi
if [ -n "$MAIL_USE_TLS" ]; then
  ckan config-tool "$config" "smtp.starttls = $MAIL_USE_TLS"
fi
if [ -n "$MAIL_USERNAME" ]; then
  ckan config-tool "$config" "smtp.user = $MAIL_USERNAME"
fi
if [ -n "$MAIL_PASSWORD" ]; then
  ckan config-tool "$config" "smtp.password = $MAIL_PASSWORD"
fi
if [ -n "$MAIL_FROM" ]; then
  ckan config-tool "$config" "smtp.mail_from = $MAIL_FROM"
fi
if [ -n "$FEEDBACK_RECIPIENTS" ]; then
  ckan config-tool "$config" "feedback.recipients = $FEEDBACK_RECIPIENTS"
fi

exec "$@"

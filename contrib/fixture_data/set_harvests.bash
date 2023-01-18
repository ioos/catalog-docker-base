# create default harvests for IOOS catalog if they don't exist.
api_key=${1?The API key must be set}

# first, try to load the organizations

ckanapi load organizations -I "$(dirname "$0")/default_organizations.jsonl" \
        -r http://localhost:5000 -a "$api_key"

# pretty slow right now

while IFS='@' read title group url; do
  source_name=${title,,}
  source_name=${source_name// /-}
  if ckan -c /etc/ckan/production.ini harvester source show "$source_name"  > /dev/null 2>&1; then
    echo "${group}-waf already exists"
  else
    ckan -c /etc/ckan/production.ini harvester source create "$source_name" "$url" 'ioos_waf' "$title WAF" 'true' "$group" 'DAILY' ''
  fi
done < datasources.txt

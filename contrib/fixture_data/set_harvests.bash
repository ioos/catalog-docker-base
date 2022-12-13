# create default harvests for IOOS catalog if they don't exist.
api_key=${1?The API key must be set}

# first, try to load the organizations

ckanapi load organizations -I "$(dirname "$0")/default_organizations.jsonl" \
        -r http://localhost:5000 -a "$api_key"

# pretty slow right now

while IFS='@' read title group url; do
  if ckan -c /etc/ckan/production.ini harvester source show "${group}-waf"  > /dev/null 2>&1; then
    echo "${group}-waf already exists"
  else
    ckan -c /etc/ckan/production.ini harvester source create "${group}-waf" "$url" 'ioos_waf' "$title WAF" 'true' "$group" 'DAILY' ''
  fi
done <<EOF
Glider DAC@glider-dac@https://registry.ioos.us/waf/Glider%20DAC/
CDIP@cdip@https://registry.ioos.us/waf/CDIP/
COMT@comt@https://registry.ioos.us/waf/COMT/
CeNCOOS@cencoos@https://registry.ioos.us/waf/CeNCOOS/
GCOOS@gcoos@https://registry.ioos.us/waf/GCOOS/
GLOS@glos@https://registry.ioos.us/waf/GLOS/
HF Radar DAC@hf-radar-dac@https://registry.ioos.us/waf/HF%20Radar%20DAC/
IOOS@ioos@https://registry.ioos.us/waf/IOOS/
MARACOOS@maracoos@https://registry.ioos.us/waf/MARACOOS/
NANOOS@nanoos@https://registry.ioos.us/waf/NANOOS/
NERACOOS@neracoos@https://registry.ioos.us/waf/NERACOOS/
NOAA CO-OOPS@noaa-co-ops@https://registry.ioos.us/waf/NOAA%20CO-OPS/
NOAA NDBC@noaa-ndbc@https://registry.ioos.us/waf/NOAA%20NDBC/
PacIOOS@pacioos@https://registry.ioos.us/waf/PacIOOS/
SCCOOS@sccoos@https://registry.ioos.us/waf/SCCOOS/
SECOORA@secoora@https://registry.ioos.us/waf/SECOORA/
CarICOOS@caricoos@https://registry.ioos.us/waf/CariCOOS/
US Navy@us-navy@https://registry.ioos.us/waf/US%20Navy/
USGS@usgs@https://registry.ioos.us/waf/USGS/
Unidata@unidata@https://registry.ioos.us/waf/Unidata/
AOOS@aoos@https://registry.ioos.us/waf/AOOS/
EOF

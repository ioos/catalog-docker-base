#!/usr/bin/env bash
set -e

# Used to install custom Solr schema on Docker container
# instead of CKAN managed schema

if [[ $BASH_SOURCE = */* ]]; then
    source_dir="${BASH_SOURCE%/*}"
else
    source_dir="$PWD"
fi
solr_container_name=${1:-solr}

# 1) Copy over changes to managed-schema file

docker cp "$source_dir/../solr/schema.xml" "$solr_container_name":/var/solr/data/ckan/conf/managed-schema

# 2) Copy managed-schema to schema.xml
docker exec "$solr_container_name" cp /var/solr/data/ckan/conf/managed-schema /var/solr/data/ckan/conf/schema.xml

# 3) Set ClassicIndexSchemaFactory in solrconfig.xml
#docker exec "$solr_container_name" sed -i '/^updateProcessor/i\  <schemaFactory class="ClassicIndexSchemaFactory"\/>' /var/solr/data/ckan/conf/solrconfig.xml
docker exec "$solr_container_name" sed -i "0,/^[[:space:]]*<updateProcessor/s@@<schemaFactory class=\"ClassicIndexSchemaFactory\"/>\n\0@" /var/solr/data/ckan/conf/solrconfig.xml

# 4) Restart solr
docker restart "$solr_container_name"

# 5) Remove ClassicIndexSchemaFactory
docker exec "$solr_container_name" sed -i '/<schemaFactory class="ClassicIndexSchemaFactory"\/>/d' /var/solr/data/ckan/conf/solrconfig.xml

# 6) restart solr again
docker restart "$solr_container_name"

# 7) rebuild index
# needs to wait
# TODO: Find out way to determine when Solr is ready
echo 'Schema move complete. Run `docker exec ckan ckan -c /srv/app/production.ini search-index rebuild` once solr is ready'

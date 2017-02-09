#!/bin/bash

$CKAN_HOME/bin/paster --plugin=ckan search-index rebuild -c $CKAN_CONFIG/ckan.ini $@

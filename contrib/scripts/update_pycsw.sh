#!/bin/bash

$CKAN_HOME/bin/paster --plugin=ckanext-spatial ckan-pycsw load -p $CKAN_CONFIG/pycsw.cfg -u http://ckan:8080/

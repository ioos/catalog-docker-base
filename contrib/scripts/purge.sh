#!/bin/bash

PGPASSWORD=$POSTGRES_PASSWORD psql -h postgis -U ckanadmin ckan < /scripts/purge.sql

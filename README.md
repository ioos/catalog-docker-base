# catalog-docker-base
Docker Image for the base CKAN build for all CKAN related images

## Test build for CKAN 2.8

To run, please have `docker` and `docker-compose` installed and run the
following in this order:

```sh
cd compose_build/
cp .env.template .env
```

- Edit `.env` to the desired configuration for your server
(TODO: Add loops to check if the DB is initialized so we don't have to go through this)
To initialize the database tables, run
```sh
docker-compose up -d solr db redis
docker-compose up -d ckan datapusher
docker-compose up -d pycsw ckan_fetch_harvester ckan_gather_harvester
```

The CKAN application runs on port 5000 by default.  PyCSW runs on port 8000 by
default on the `/csw` endpoint.
Once the database has been successfully been initialized, you will probably be
able to start the applications just by using `docker-compose up -d` in
subsequent invocations.

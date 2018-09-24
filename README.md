# catalog-docker-base
Docker Image for the base CKAN build for all CKAN related images

## Build for CKAN 2.8

To run, please have `docker` and `docker-compose` installed and run the
following in this order:

```sh
git clone --recurse-submodules https://github.com/ioos/catalog-docker-base.git
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

## Create a superuser

Run `docker exec -it ckan ckan-paster --plugin ckan sysadmin add <username> -c /etc/ckan/production.ini`
to add a superuser to CKAN.

### Optional: Load harvester config

Run `docker exec ckan bash /opt/fixture_data/set_harvests.bash <API_KEY>` in order to
load up the default IOOS harvests.  The API key for a particular user can be
found on the user account page of the CKAN website or from the output of the previously listed sysadmin command. 
The API key must correspond to a user with sufficient privileges to create groups/organizations.

Lastly, run `crontab -e` and add the following line to ensure the harvester
is periodically run:

```sh
*/2 * * * * docker exec ckan /usr/lib/ckan/venv/bin/paster --plugin=ckanext-harvest harvester -c /etc/ckan/production.ini run
```

# catalog-docker-base
Docker Image for the base CKAN build for all CKAN related images

## Build for CKAN 2.10

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

Run `docker exec -it ckan ckan -c /etc/ckan/production.ini sysadmin add <username>`
to add a superuser to CKAN.

### Optional: Load harvester config

Run `docker exec ckan ckan -c /etc/ckan/production.ini user token add <username> <token_name>`, using the user name from the previous step in "Create a superuser".
Copy the generated token value in the terminal and then run `docker exec ckan bash /opt/fixture_data/set_harvests.bash <token_value>` using the previously copied token value in order to
load up the default IOOS harvests.  The token value must correspond to a user with sufficient privileges to create groups/organizations, hence why a superuser token is supplied in this example.

Lastly, run `crontab -e` and add the following line to ensure the harvester
is periodically run:

```sh
*/2 * * * * docker exec ckan ckan -c /etc/ckan/production.ini harvester run
```

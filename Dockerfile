# main ckan repo does not use versioning and could break, use Luke's version 
# which freezes version
FROM lukecampbell/ckan

# Install git
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y git libgeos-dev libxml2-dev libxslt1-dev supervisor postgresql-client

# Install the CKAN Spatial extension
# CKAN spatial extension has no tagged Git releases currently, so freeze the
# version at a known good commit to prevent breakage from later versions

# BWA: Use commit off master branch to fix tile issues.  Replaces MapQuest
#      tiles with Stamen tiles.
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/ioos/ckanext-spatial.git@eb654a1af73247f317306759755070ce8fd87327#egg=ckanext-spatial
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/ckanext-spatial/pip-requirements.txt

# must use this commit or similar as tagged versions cause "Add harvests" page
# to display no fields.  Harvests may also fail to initialize, delete, or run
# possibly due to breaking API changes.
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/benjwadams/ckanext-harvest.git@race_condition_graceful_death_old#egg=ckanext-harvest
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/ckanext-harvest/pip-requirements.txt

RUN $CKAN_HOME/bin/pip install -e git+https://github.com/geopython/pycsw.git@1.10.5#egg=pycsw
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/pycsw/requirements.txt

RUN $CKAN_HOME/bin/pip install -e git+https://github.com/ioos/catalog-ckan.git@5ea68429c5be3ca648e6c90bf5c8364d280f287f#egg=ckanext-ioos-theme

# Set CKAN_INIT 
ENV CKAN_INIT="true"


# Add my custom configuration file
COPY ./contrib/config/pycsw/default.cfg $CKAN_HOME/src/pycsw/default.cfg
COPY ./contrib/config/pycsw/pycsw.wsgi $CKAN_CONFIG/pycsw.wsgi


# Configure nginx
COPY ./contrib/config/nginx.conf /etc/nginx/nginx.conf

COPY ./contrib/my_init.d /etc/my_init.d
COPY ./contrib/supervisor/conf.d /etc/supervisor/conf.d

COPY ./contrib/services /bin/services

# run the init script
CMD ["/sbin/my_init"]

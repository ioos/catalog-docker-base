# main ckan repo does not use versioning and could break, use Luke's version 
# which freezes version
FROM ioos/ckan:1.0.0

# Install git
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y git libgeos-dev libxml2-dev libxslt1-dev supervisor postgresql-client

# Install the CKAN Spatial extension
# CKAN spatial extension has no tagged Git releases currently, so freeze the
# version at a known good commit to prevent breakage from later versions

# The prior image built upon was pretty old, so make sure the certificates
# are updated, so Python pip packages properly install, etc.
RUN $CKAN_HOME/bin/pip install certifi>=2018.8.24
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/ioos/ckanext-spatial.git#egg=ckanext-spatial
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/ckanext-spatial/pip-requirements.txt

# must use this commit or similar as tagged versions cause "Add harvests" page
# to display no fields.  Harvests may also fail to initialize, delete, or run
# possibly due to breaking API changes.
RUN $CKAN_HOME/bin/pip install -e git+https://github.com/ioos/ckanext-harvest.git@catalog_compat#egg=ckanext-harvest
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/ckanext-harvest/pip-requirements.txt

RUN $CKAN_HOME/bin/pip install -e git+https://github.com/benjwadams/pycsw.git@link_split_fix_1.10.5#egg=pycsw
RUN $CKAN_HOME/bin/pip install -r $CKAN_HOME/src/pycsw/requirements.txt

RUN "$CKAN_HOME/bin/pip" install --upgrade pip

# optional, but ships with the image by default
RUN "$CKAN_HOME/bin/pip" install -e git+https://github.com/ckan/ckanext-googleanalytics.git#egg=ckanext-googleanalytics && \
    "$CKAN_HOME/bin/pip" install -r "$CKAN_HOME/src/ckanext-googleanalytics/requirements.txt"

RUN $CKAN_HOME/bin/pip install -e git+https://github.com/ioos/catalog-ckan.git@1.2.3#egg=ckanext-ioos-theme

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
COPY ./contrib/scripts /scripts

# run the init script
CMD ["/sbin/my_init"]

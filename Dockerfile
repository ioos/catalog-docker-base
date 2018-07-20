FROM docker_ckan:2.8.0

USER root
# Install git
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -q -y git libgeos-dev libxml2-dev libxslt1-dev
# Add my custom configuration file
COPY ./contrib/config/pycsw/default.cfg $CKAN_CONFIG/pycsw/default.cfg
COPY ./contrib/config/pycsw/pycsw.wsgi $CKAN_CONFIG/pycsw.wsgi
#RUN apt install -q -y python-pip python-virtualenv
#RUN "$CKAN_VENV/bin"
RUN ckan-pip install --upgrade pip
# Install the CKAN Spatial extension
# CKAN spatial extension has no tagged Git releases currently, so freeze the
# version at a known good commit to prevent breakage from later versions

# BWA: Use commit off master branch to fix tile issues.  Replaces MapQuest
#      tiles with Stamen tiles.
RUN ckan-pip install git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial
#RUN ckan-pip install -r "$CKAN_VENV/src/ckanext-spatial/pip-requirements.txt"

# must use this commit or similar as tagged versions cause "Add harvests" page
# to display no fields.  Harvests may also fail to initialize, delete, or run
# possibly due to breaking API changes.
RUN ckan-pip install git+https://github.com/ckan/ckanext-harvest.git#egg=ckanext-harvest
#RUN ckan-pip install -r "$CKAN_VENV/src/ckanext-harvest/pip-requirements.txt"

RUN ckan-pip install git+https://github.com/geopython/pycsw.git@1.10.5#egg=pycsw
#RUN ckan-pip install -r "$CKAN_VENV/src/pycsw/requirements.txt"


# optional, but ships with the image by default
RUN ckan-pip install git+https://github.com/ckan/ckanext-googleanalytics.git#egg=ckanext-googleanalytics 
#    ckan-pip install -r "$CKAN_VENV/src/ckanext-googleanalytics/requirements.txt"

RUN ckan-pip install git+https://github.com/ioos/catalog-ckan.git@1.2.2#egg=ckanext-ioos-theme

RUN ckan-pip install psycopg2
# note: modifies ckan

COPY ./contrib/scripts/check_plugins.bash /check_plugins.bash
RUN chmod +x /check_plugins.bash
ENTRYPOINT ["/check_plugins.bash"]
USER ckan

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]

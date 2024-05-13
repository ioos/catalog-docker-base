FROM keitaro/ckan:2.10.4-focal

USER root
# Add my custom configuration file
COPY "./contrib/config/pycsw/pycsw.cfg" "$CKAN_CONFIG/"
COPY "./contrib/scripts/" "/usr/local/bin/"
RUN apt-get update -y && \
    #apt-get install -y debian-archive-keyring && \
    apt-get install -q --force-yes -y git libgeos-dev \
                         libxml2-dev \
                         libxslt1-dev \
                         zlib1g-dev \
                         libudunits2-dev && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

# pip install must be run with -e and then requirements manually installed
# in order for most CKAN plugins to work!
RUN pip install --no-cache-dir -U pip && \
    pip install --no-cache-dir \
       wheel flask_debugtoolbar oauth2client && \
    pip install -e git+https://github.com/ioos/ckanext-spatial.git@ioos_ckan_master_rebase_2#egg=ckanext-spatial \
       -e git+https://github.com/ckan/ckanext-harvest.git#egg=ckanext-harvest \
       -e git+https://github.com/ioos/ckanext-ioos-theme.git@main#egg=ckanext-ioos-theme \
       -e git+https://github.com/ckan/ckanext-googleanalytics.git#egg=ckanext-googleanalytics \
       -e git+https://github.com/ckan/ckanext-dcat.git@master#egg=ckanext-dcat

# for ckan harvester run-test command
RUN pip install --no-cache-dir factory_boy mock pytest

RUN pip install --no-cache-dir \
       -r "/srv/app/src/ckanext-spatial/requirements.txt" && \
    pip install --no-cache-dir \
       -r "/srv/app/src/ckanext-ioos-theme/requirements.txt" \
       -r "/srv/app/src/ckanext-harvest/pip-requirements.txt" \
       -r "/srv/app/src/ckanext-googleanalytics/requirements.txt" \
       -r "/srv/app/src/ckanext-dcat/requirements.txt" pycsw cf-units && \
    pip install --no-cache-dir -r "/srv/app/src/ckanext-harvest/pip-requirements.txt" && \
    # fixme: update pycsw version
    #ckan-pip3 install --no-cache-dir pycsw==1.8.6 Shapely==1.5.17 \
    #                                OWSLib==0.16.0 lxml==3.6.2 && \
    pip install --no-cache-dir ckanapi rdflib future 'six>=1.12.0'

# the above appears to be necessary to run separately, or otherwise it results
# in a double requirements error with the above requirements files

COPY ./contrib/scripts/check_plugins.bash /
COPY ./contrib/fixture_data /opt/fixture_data
COPY ./contrib/solr/schema.xml /usr/lib/ckan/venv/src/ckan/ckan/config/solr/
RUN chmod +x /check_plugins.bash /opt/fixture_data/set_harvests.bash
# PyCSW config is hardcoded for the time being
COPY ./contrib/config/pycsw/pycsw.cfg /etc/pycsw/pycsw.cfg
ENTRYPOINT ["/check_plugins.bash"]
USER ckan

EXPOSE 5000
CMD ["ckan","-c","/srv/app/production.ini", "run", "--host", "0.0.0.0"]

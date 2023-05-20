FROM docker_ckan

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
                         #zlib1g=1:1.2.8.dfsg-2+deb8u1 \
                         #zlib1g-dev=1:1.2.8.dfsg-2+deb8u1 && \
    apt-get -q clean && \
    rm -rf /var/lib/apt/lists/*

# pip install must be run with -e and then requirements manually installed
# in order for most CKAN plugins to work!
RUN ckan-pip3 install --no-cache-dir -U pip && \
    ckan-pip3 install --no-cache-dir \
       wheel flask_debugtoolbar && \ 
    ckan-pip3 install -e git+https://github.com/ioos/ckanext-spatial.git@ioos_ckan_master_rebase#egg=ckanext-spatial \
       #ckan-pip3 install -e git+https://github.com/ckan/ckanext-spatial.git@smellman-dev-py3#egg=ckanext-spatial \
       #-e git+https://github.com/ckan/ckanext-harvest.git@v1.3.1#egg=ckanext-harvest \
       -e git+https://github.com/ckan/ckanext-harvest.git#egg=ckanext-harvest \
       -e git+https://github.com/ioos/ckanext-ioos-theme.git@2d44041f4a0023b6a13539631cedd28c5658e998#egg=ckanext-ioos-theme \
       #-e git+https://github.com/benjwadams/ckanext-ioos-theme.git@remove_metocean_keywords#egg=ckanext-ioos-theme \
       -e git+https://github.com/ckan/ckanext-dcat.git@master#egg=ckanext-dcat
       #-e git+https://github.com/ioos/ckanext-sitemap@no_rev_time_handle#egg=ckanext-sitemap \
       #-e git+https://github.com/ckan/ckanext-harvest.git@master#egg=ckanext-harvest \
       #-e git+https://github.com/ckan/ckanext-harvest.git@v1.3.3#egg=ckanext-harvest \
       #-e git+https://github.com/ckan/ckanext-showcase@v1.4.3#egg=ckanext-showcase && \

RUN ckan-pip3 install --no-cache-dir \
       -r "$CKAN_VENV/src/ckanext-spatial/requirements.txt" && \
    ckan-pip3 install --no-cache-dir \
       -r "$CKAN_VENV/src/ckanext-ioos-theme/requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-harvest/pip-requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-dcat/requirements.txt" pycsw cf-units && \
       #-r "$CKAN_VENV/src/ckanext-googleanalytics/requirements.txt" \
    ckan-pip3 install --no-cache-dir -r "$CKAN_VENV/src/ckanext-harvest/pip-requirements.txt" && \
    # fixme: update pycsw version
    #ckan-pip3 install --no-cache-dir pycsw==1.8.6 Shapely==1.5.17 \
    #                                OWSLib==0.16.0 lxml==3.6.2 && \
    #ckan-pip3 install --no-cache-dir lxml>=3.6.2 && \
    ckan-pip3 install --no-cache-dir ckanapi rdflib future 'six>=1.12.0'

# the above appears to be necessary to run separately, or otherwise it results
# in a double requirements error with the above requirements files

COPY ./contrib/scripts/check_plugins.bash /
COPY ./contrib/fixture_data /opt/fixture_data
COPY ./.base_ckan/ckan/config/solr/schema.xml /usr/lib/ckan/venv/src/ckan/ckan/config/solr/
RUN chmod +x /check_plugins.bash /opt/fixture_data/set_harvests.bash
# PyCSW config is hardcoded for the time being
COPY ./contrib/config/pycsw/pycsw.cfg /etc/pycsw/pycsw.cfg
ENTRYPOINT ["/check_plugins.bash"]
USER ckan

EXPOSE 5000
CMD ["ckan","-c","/etc/ckan/production.ini", "run", "--host", "0.0.0.0"]

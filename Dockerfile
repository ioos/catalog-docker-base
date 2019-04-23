FROM ioos/ckan:2.8.2

USER root
# Add my custom configuration file
COPY "./contrib/config/pycsw/pycsw.cfg" "$CKAN_CONFIG/"
# BWA (2019-03-29) need to update debian jessie sources for updates
COPY "./contrib/config/sources.list" "/etc/apt/sources.list"
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
                                   apt-get install -q -y git libgeos-dev \
                                                        libxml2-dev \
                                                         libxslt1-dev && \
                                   apt-get -q clean && \
                                   rm -rf /var/lib/apt/lists/*

# pip install must be run with -e and then requirements manually installed
# in order for most CKAN plugins to work!
RUN wget 'https://bootstrap.pypa.io/get-pip.py' && python get-pip.py && \
    ckan-pip install --no-cache-dir --upgrade 'certifi>=2018.10.15' \
                                              'setuptools' && \
    ckan-pip install --no-cache-dir 'pendulum==2.0.3' && \
    ckan-pip install --no-cache-dir --trusted-host files.pythonhosted.org \
       -e git+https://github.com/ckan/ckanext-googleanalytics.git@v2.0.2#egg=ckanext-googleanalytics \
       -e git+https://github.com/ioos/ckanext-spatial.git@ioos_ckan_master_rebase#egg=ckanext-spatial \
       -e git+https://github.com/ckan/ckanext-harvest.git@v1.1.1#egg=ckanext-harvest \
       -e git+https://github.com/ckan/ckanext-dcat.git@v0.0.8#egg=ckanext-dcat \
       -e git+https://github.com/ioos/catalog-ckan.git@9ae86d006f6045e230721e463eb5e9b32df8e1f2#egg=ckanext-ioos-theme \
       -e git+https://github.com/ioos/ckanext-sitemap@no_rev_time_handle#egg=ckanext-sitemap && \
    ckan-pip install --no-cache-dir \
       -r "$CKAN_VENV/src/ckanext-spatial/pip-requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-harvest/pip-requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-googleanalytics/requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-dcat/requirements.txt" && \
    ckan-pip install -r "$CKAN_VENV/src/ckanext-sitemap/requirements.txt" && \
    # fixme: update pycsw version
    ckan-pip install --no-cache-dir pycsw==1.8.6 Shapely==1.5.17 \
                                    OWSLib==0.16.0 lxml==3.6.2 && \
    pip install ckanapi

# the above appears to be necessary to run separately, or otherwise it results
# in a double requirements error with the above requirements files

COPY ./contrib/scripts/check_plugins.bash /
COPY ./contrib/fixture_data /opt/fixture_data
RUN chmod +x /check_plugins.bash /opt/fixture_data/set_harvests.bash
# PyCSW config is hardcoded for the time being
COPY ./contrib/config/pycsw/pycsw.cfg /etc/pycsw/pycsw.cfg
ENTRYPOINT ["/check_plugins.bash"]
USER ckan

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]

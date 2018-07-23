FROM docker_ckan:2.8.0

USER root
# Add my custom configuration file
COPY ["./contrib/config/pycsw/default.cfg" \
      "./contrib/config/pycsw/pycsw.wsgi" "$CKAN_CONFIG/"]
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
                                   apt-get install -q -y git libgeos-dev \
                                                        libxml2-dev \
                                                         libxslt1-dev && \
                                   apt-get -q clean && \
                                   rm -rf /var/lib/apt/lists/*

RUN ckan-pip install --no-cache-dir \
       -e git+https://github.com/ckan/ckanext-googleanalytics.git#egg=ckanext-googleanalytics \
       -e git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial \
       -e git+https://github.com/ckan/ckanext-harvest.git#egg=ckanext-harvest \
       -e git+https://github.com/ioos/catalog-ckan.git@1.2.2#egg=ckanext-ioos-theme &&\
    ckan-pip install --no-cache-dir \
       -r "$CKAN_VENV/src/ckanext-spatial/pip-requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-harvest/pip-requirements.txt" \
       -r "$CKAN_VENV/src/ckanext-googleanalytics/requirements.txt"

COPY ./contrib/scripts/check_plugins.bash /check_plugins.bash
RUN chmod +x /check_plugins.bash
ENTRYPOINT ["/check_plugins.bash"]
USER ckan

CMD ["ckan-paster","serve","/etc/ckan/production.ini"]

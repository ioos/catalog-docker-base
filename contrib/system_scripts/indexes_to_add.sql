-- list of indexes which can help speed up some CKAN queries

CREATE INDEX CONCURRENTLY IF NOT EXISTS
  harvest_object_package_id_fkey_current_partial
  ON public.harvest_object (package_id) WHERE current;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_resource_fk_package_id ON
  resource_revision (package_id);

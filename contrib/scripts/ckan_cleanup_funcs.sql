BEGIN;

CREATE OR REPLACE FUNCTION delete_marked_packages()
    RETURNS void AS $$
        UPDATE package set state = 'to_delete' where state <> 'to_delete' AND state <> 'active' OR owner_org is null;
        DELETE from resource_revision where package_id in (select id from package where state = 'to_delete' );
        DELETE from package_tag_revision where package_id in (select id from package where state = 'to_delete');
        DELETE from member_revision where table_id in (select id from package where state = 'to_delete');
        DELETE from package_extra_revision where package_id in (select id from package where state = 'to_delete');
        DELETE from package_revision where id in (select id from package where state = 'to_delete');
        DELETE from package_tag where package_id in (select id from package where state = 'to_delete');
        DELETE from resource_view where resource_id in (select id from resource where package_id in (select id from package where state = 'to_delete'));
        DELETE from resource where package_id in (select id from package where state = 'to_delete');
        DELETE from package_extra where package_id in (select id from package where state = 'to_delete');
        DELETE from member where table_id in (select id from package where state = 'to_delete');
        DELETE from harvest_object_error hoe using harvest_object ho where ho.id = hoe.harvest_object_id and package_id  in (select id from package where state = 'to_delete');
        DELETE from harvest_object_extra hoe using harvest_object ho where ho.id = hoe.harvest_object_id and package_id  in (select id from package where state = 'to_delete');
        DELETE from harvest_object where package_id in (select id from package where state = 'to_delete');
        DELETE from package_extent where package_id in (select id from package where state = 'to_delete');
        DELETE from package where id in (select id from package where state = 'to_delete');
    $$ LANGUAGE sql;
COMMENT ON FUNCTION delete_marked_packages() IS 'Clears packages from the database which are marked for deletion';
REVOKE ALL ON FUNCTION delete_marked_packages() FROM PUBLIC;


CREATE OR REPLACE FUNCTION trunc_activity()
    RETURNS void AS $$
    TRUNCATE activity_detail;
    TRUNCATE activity; $$ LANGUAGE sql;
COMMENT ON FUNCTION trunc_activity() IS 'Clears activity* tables';
REVOKE ALL ON FUNCTION trunc_activity() FROM PUBLIC;


CREATE OR REPLACE FUNCTION delete_old_harvests()
    RETURNS void AS $$
    delete from harvest_object where id not in (
        select distinct on(ho.package_id) ho.id from harvest_object ho
        join package p on p.id = ho.package_id
        order by ho.package_id, ho.import_started desc
    );
    delete from harvest_object_error where harvest_object_id not in (select id from harvest_object);
    delete from harvest_object_extra where harvest_object_id not in (select id from harvest_object); $$ LANGUAGE sql;
COMMENT ON FUNCTION delete_old_harvests() IS 'Deletes harvest objects older than the newest one';
REVOKE ALL ON FUNCTION delete_old_harvests() FROM PUBLIC;

CREATE OR REPLACE FUNCTION delete_non_current_ckan()
    RETURNS void AS $$
    -- revisions
    DELETE FROM revision WHERE id in (select revision_id from resource_revision where current is not true);
    DELETE FROM resource_revision WHERE current IS NOT true;
    DELETE from package_revision where current is not true;
    -- tags
    delete from tag where id in (select tag_id from package_tag_revision where current is not true);
    delete from package_tag where tag_id in (select tag_id from package_tag_revision where current is not true);
    delete from revision where id in (select revision_id from package_tag_revision where current is not true);
    delete from package_tag_revision where current is not true; $$ LANGUAGE sql;
COMMENT ON FUNCTION delete_non_current_ckan() IS 'Deletes non current package extras, resources, package revisions, and tags';
REVOKE ALL ON FUNCTION delete_non_current_ckan() FROM PUBLIC;

COMMIT;

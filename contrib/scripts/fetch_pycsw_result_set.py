#!/usr/bin/env python
import os
import logging
import psycopg2
import hashlib

log = logging.getLogger()
log.setLevel(logging.INFO)
console = logging.StreamHandler()
log.addHandler(console)

def main():
    """
    Load PyCSW records from a PostgreSQL database to a local output folder.
    Skips records which have unchanged content based upon MD5 sum.

    Environment variables are used by this script.  They are:
    OUTPUT_DIR (required): Directory to output records to
    DB_HOST: Host for the PostgreSQL database.  Defaults to "localhost".
    DB_PORT: Port for the PostgreSQL database.  Defaults to 5432.
    DB_NAME: Name of the PostgreSQL database.  Defaults to "ckan".
    DB_USER: PostgreSQL database user.  Defaults to "ckan".
    """

    dir_loc = os.environ['OUTPUT_DIR']
    conn = psycopg2.connect(host=os.getenv("DB_HOST", "localhost"),
                            port=os.getenv("DB_PORT", 5432),
                            dbname=os.getenv("DB_NAME", "ckan"),
                            user=os.getenv("DB_USER", "ckan"))
    serv_cursor = conn.cursor("rec_fetch")
    serv_cursor.execute('SELECT identifier, md5(xml), xml FROM records')
    for rec_id, xml_md5, rec_xml in serv_cursor:
        log.info("Processing {}".format(rec_id))
        file_path = os.path.join(dir_loc, rec_id.replace('/', '_') + '.xml')
        # possible race condition if file is deleted after checking
        try:
            if (not os.path.exists(file_path) or
                hashlib.md5(open(file_path,
                                 'rb').read()).hexdigest() != xml_md5):
                with open(file_path, 'w') as xml_file:
                    xml_file.write(rec_xml)
                log.info("Wrote xml contents to {}".format(file_path))
            else:
                log.info("{} already exists and MD5 sum unchanged, skipping...".format(rec_id))
        except:
              log.exception("Exception occurred while processing {}:".format(rec_id))


if __name__ == '__main__':
    main()

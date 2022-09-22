BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Clean tables if necessary'
DROP TABLE IF EXISTS :moduleSchema.:habitatsTmpTable;


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store habitats'
CREATE TABLE :moduleSchema.:habitatsTmpTable (
	id_habitat_taxon serial NOT NULL,
	cd_hab int4 NOT NULL,
    cd_nom int4 NOT NULL,
    comments text NULL,
    CONSTRAINT pk_:habitatsTmpTable PRIMARY KEY (id_habitat_taxon)
);


\echo '--------------------------------------------------------------------------------'
\echo 'Change tmp table owner to :dbUserName'
ALTER TABLE :moduleSchema.:habitatsTmpTable OWNER TO :dbUserName;


\echo '--------------------------------------------------------------------------------'
\echo 'Import raw habitats with COPY'
COPY :moduleSchema.:habitatsTmpTable
    (cd_hab, cd_nom, comments)
FROM :'habitatsCsvPath'
DELIMITER ',' CSV HEADER;


\echo '--------------------------------------------------------------------------------'
\echo 'Trim values in temporary habitats table'
UPDATE :moduleSchema.:habitatsTmpTable
SET
    comments = TRIM(BOTH FROM comments)
;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

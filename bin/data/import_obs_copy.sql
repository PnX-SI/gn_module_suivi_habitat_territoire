BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Import raw visits with COPY'
SET DateStyle TO 'DMY';

COPY :moduleSchema.:visitsTmpTable
    (visit_code, site_code, observers, organisms, date_min, comment, perturbations)
FROM :'visitsCsvPath'
DELIMITER ',' CSV HEADER;

SET DateStyle TO 'ISO';


\echo '--------------------------------------------------------------------------------'
\echo 'Trim values in temporary visits table'
UPDATE :moduleSchema.:visitsTmpTable
SET
    visit_code = TRIM(BOTH FROM visit_code),
    site_code = TRIM(BOTH FROM site_code),
    observers = TRIM(BOTH FROM observers),
    organisms = TRIM(BOTH FROM organisms),
    comment = TRIM(BOTH FROM comment),
    perturbations = TRIM(BOTH FROM perturbations),
    date_max = date_min
;


\echo '--------------------------------------------------------------------------------'
\echo 'Import raw observations with COPY'
COPY :moduleSchema.:obsTmpTable
    (visit_code, cd_nom, presence)
FROM :'obsCsvPath'
DELIMITER ',' CSV HEADER;


\echo '--------------------------------------------------------------------------------'
\echo 'Trim values in temporary visits table'
UPDATE :moduleSchema.:obsTmpTable
SET visit_code = TRIM(BOTH FROM visit_code)
;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

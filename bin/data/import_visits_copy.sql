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
\echo 'COMMIT if ALL is OK:'
COMMIT;


BEGIN;
\echo '--------------------------------------------------------------------------------'
\echo 'Split perturbations to insert values in link to perturbations table'
INSERT INTO :moduleSchema.:visitsHasPerturbationsTmpTable (
    id_visit, id_nomenclature_perturbation
)
    SELECT DISTINCT
        id_visit,
        ref_nomenclatures.get_id_nomenclature(
            'TYPE_PERTURBATION', 
            unnest(string_to_array(perturbations, '|'))
        )
    FROM :moduleSchema.:visitsTmpTable
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;


BEGIN;
\echo '--------------------------------------------------------------------------------'
\echo 'Split observers and organisms to insert values in observers table'
INSERT INTO :moduleSchema.:visitsObserversTmpTable (
    md5, firstname, lastname, fullname, organism
)
    SELECT DISTINCT
        md5(unnest(string_to_array(observers, '|'))) AS md5,
        split_part(unnest(string_to_array(observers, '|')), ' ', 2) AS firstname,
        split_part(unnest(string_to_array(observers, '|')), ' ', 1) AS lastname,
        unnest(string_to_array(observers, '|')) AS split_observer,
        unnest(string_to_array(organisms, '|')) AS split_organism
    FROM :moduleSchema.:visitsTmpTable AS v
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;


BEGIN;
\echo '--------------------------------------------------------------------------------'
\echo 'Link visits table with observers temporary table'
INSERT INTO :moduleSchema.:visitsHasObserversTmpTable (id_visit, id_observer)
    SELECT v.id_visit, o.id_observer
    FROM :moduleSchema.:visitsTmpTable AS v
        LEFT JOIN LATERAL unnest(string_to_array(observers, '|')) AS sob(split_observer)
            ON true
        JOIN :moduleSchema.:visitsObserversTmpTable as o
            ON (sob.split_observer = o.fullname)
ON CONFLICT DO NOTHING;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

BEGIN;

-- Import raw visit with COPY
SET DateStyle TO 'DMY';

COPY :moduleSchema.:visitsTmpTable
    (site_code, meshe_code, observers, organisms, date_min, date_max, presence)
FROM :'visitsCsvPath'
DELIMITER ',' CSV HEADER;

SET DateStyle TO 'ISO';


-- Trim values in temporary visits table
UPDATE :moduleSchema.:visitsTmpTable
SET
    meshe_code = TRIM(BOTH FROM meshe_code),
    observers = TRIM(BOTH FROM observers),
    organisms = TRIM(BOTH FROM organisms),
    presence = TRIM(BOTH FROM presence)
;

COMMIT;

BEGIN;
-- Split observers and organisms to insert values in observers table
INSERT INTO :moduleSchema.:visitsObserversTmpTable (md5, firstname, lastname, fullname, organism)
    SELECT DISTINCT
        md5(unnest(string_to_array(observers, '|'))) AS md5,
        split_part(unnest(string_to_array(observers, '|')), ' ', 2) AS firstname,
        split_part(unnest(string_to_array(observers, '|')), ' ', 1) AS lastname,
        unnest(string_to_array(observers, '|')) AS split_observer,
        unnest(string_to_array(organisms, '|')) AS split_organism
    FROM :moduleSchema.:visitsTmpTable AS v
ON CONFLICT DO NOTHING;

COMMIT;
BEGIN;

-- Link meshes visits table with observers temporary table
INSERT INTO :moduleSchema.:visitsHasObserversTmpTable (id_visit_meshe, id_observer)
    SELECT v.id_visit_meshe, o.id_observer
    FROM :moduleSchema.:visitsTmpTable AS v
        LEFT JOIN LATERAL unnest(string_to_array(observers, '|')) AS sob(split_observer)
            ON true
        JOIN :moduleSchema.:visitsObserversTmpTable as o
            ON (sob.split_observer = o.fullname)
ON CONFLICT DO NOTHING;

COMMIT;

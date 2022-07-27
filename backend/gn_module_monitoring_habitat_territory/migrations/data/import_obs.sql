-- Script SQL to import observations from temporary tables (use with `import_observations.sh`)
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Update site id in temporary visits table'
WITH sites AS (
    SELECT
        id_base_site AS id,
        base_site_code AS site_code
    FROM gn_monitoring.t_base_sites
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET site_id = sites.id
FROM sites
WHERE vt.site_code = sites.site_code;


\echo '--------------------------------------------------------------------------------'
\echo 'Update visit, dataset and module id in temporary visits table'
WITH visits AS (
    SELECT
        bv.id_base_visit AS id,
        bv.id_base_site AS id_site,
        bv.id_dataset,
        bv.id_module,
        bv.uuid_base_visit AS uuid,
        bv.visit_date_min AS date_min,
        bv.visit_date_max AS date_max
    FROM gn_monitoring.t_base_visits AS bv
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET
    visit_id = v.id,
    visit_uuid = v.uuid,
    module_id = v.id_module,
    dataset_id = v.id_dataset
FROM visits AS v
WHERE vt.site_id = v.id_site
    AND vt.date_min = v.date_min
    AND vt.date_max = v.date_max ;


\echo '--------------------------------------------------------------------------------'
\echo 'Update visit id in temporary observations table'
WITH visits AS (
    SELECT visit_id AS id, visit_code AS code
    FROM :moduleSchema.:visitsTmpTable
)
UPDATE :moduleSchema.:obsTmpTable AS ot
SET visit_id = visits.id
FROM visits
WHERE ot.visit_code = visits.code;


\echo '--------------------------------------------------------------------------------'
\echo 'Add new observations if not already exists'
INSERT INTO :moduleSchema.cor_visit_taxons (id_base_visit, cd_nom)
    SELECT DISTINCT ot.visit_id, ot.cd_nom
    FROM :moduleSchema.:obsTmpTable AS ot
    WHERE presence = TRUE
        AND NOT EXISTS (
            SELECT 'X'
            FROM :moduleSchema.cor_visit_taxons AS cvt
            WHERE cvt.id_base_visit = ot.visit_id
                AND cvt.cd_nom = ot.cd_nom
        ) ;

\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

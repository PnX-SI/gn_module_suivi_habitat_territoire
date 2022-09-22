-- Script SQL to delete visits from temporary tables (use with `import_visits.sh -d`)
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Update module and site id in temporary visit table'
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
\echo 'Update organism and role id in temporary observers table'
WITH users AS (
    SELECT
        r.id_role AS id,
        r.prenom_role AS firstname,
        r.nom_role AS lastname,
        o.id_organisme AS id_organism,
        o.nom_organisme AS organism
    FROM utilisateurs.t_roles AS r
        JOIN utilisateurs.bib_organismes AS o
            ON (r.id_organisme = o.id_organisme)
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET
    role_id = u.id,
    organism_id = u.id_organism
FROM users AS u
WHERE
    u.firstname ILIKE ot.firstname
    AND u.lastname ILIKE ot.lastname
    AND u.organism ILIKE ot.organism;


\echo '--------------------------------------------------------------------------------'
\echo 'Update roles added with current import only'
-- TODO: find a better way to mark users added by current import
WITH observers_list AS (
    SELECT id_liste AS id
    FROM utilisateurs.t_listes
    WHERE code_liste = :'observersListCode'
),
users AS (
    SELECT
        r.id_role AS id
    FROM utilisateurs.t_roles AS r
        JOIN utilisateurs.cor_role_liste AS rl
            ON (r.id_role = rl.id_role)
        JOIN observers_list AS ol
            ON (rl.id_liste = ol.id)
    WHERE r.identifiant IS NULL
        AND r.active = False
        AND champs_addi @> json_build_object('sht', json_build_object('importDate', :'importDate'))::jsonb
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET role_added = True
FROM users AS u
WHERE u.id = ot.role_id ;


\echo '--------------------------------------------------------------------------------'
\echo 'Update organisms added with current import only'
-- TODO: find a better way to mark organism added by current import
WITH not_added_organisms AS (
    SELECT DISTINCT id_organisme AS id
    FROM utilisateurs.t_roles
    WHERE id_organisme IS NOT NULL
		AND (
			active = True
	        OR NOT(champs_addi @> json_build_object('sht', json_build_object('importDate', :'importDate'))::jsonb)
            OR champs_addi IS NULL
	    )
), roles_with_organism_added AS (
	SELECT DISTINCT role_id AS id
	FROM :moduleSchema.:visitsObserversTmpTable
	WHERE organism_id NOT IN (SELECT id FROM not_added_organisms)
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET organism_added = True
FROM roles_with_organism_added AS r
WHERE ot.role_id = r.id;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

BEGIN;
\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM cor_visit_perturbation in SHT schema'
DELETE FROM :moduleSchema.cor_visit_perturbation
USING :moduleSchema.:visitsTmpTable AS vt
WHERE id_base_visit = vt.visit_id ;


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM cor_visit_taxons in SHT schema'
DELETE FROM :moduleSchema.cor_visit_taxons
USING :moduleSchema.:visitsTmpTable AS vt
WHERE id_base_visit = vt.visit_id ;


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM gn_monitoring.cor_visit_observer'
DELETE FROM gn_monitoring.cor_visit_observer AS o
WHERE EXISTS (
    SELECT DISTINCT vt.visit_id, vo.role_id
    FROM :moduleSchema.:visitsTmpTable AS vt
        JOIN :moduleSchema.:visitsHasObserversTmpTable AS vho
            ON (vt.id_visit = vho.id_visit)
        JOIN :moduleSchema.:visitsObserversTmpTable AS vo
            ON (vho.id_observer = vo.id_observer)
    WHERE vt.visit_id = o.id_base_visit
        AND vo.role_id = o.id_role
);


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM utilisateurs.cor_role_list'
WITH observers_list AS (
    SELECT id_liste AS id
    FROM utilisateurs.t_listes
    WHERE code_liste = :'observersListCode'
)
DELETE FROM utilisateurs.cor_role_liste
USING :moduleSchema.:visitsObserversTmpTable AS o, observers_list AS ol
WHERE id_role = o.role_id
    AND id_liste = ol.id
    AND o.role_added = True;


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM utilisateurs.t_roles'
DELETE FROM utilisateurs.t_roles
USING :moduleSchema.:visitsObserversTmpTable AS vo
WHERE id_role = vo.role_id
    AND vo.role_added = True ;


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM utilisateurs.bib_organismes'
DELETE FROM utilisateurs.bib_organismes
USING :moduleSchema.:visitsObserversTmpTable AS vo
WHERE id_organisme = vo.organism_id
    AND vo.organism_added = True ;


\echo '--------------------------------------------------------------------------------'
\echo 'DELETE FROM gn_monitoring.t_base_visits'
DELETE FROM gn_monitoring.t_base_visits
USING :moduleSchema.:visitsTmpTable AS vt
WHERE id_base_visit = vt.visit_id ;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

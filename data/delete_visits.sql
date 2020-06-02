-- Script SQL to delete visits from temporary tables (use with `import_visits.sh -d`)
BEGIN;

-- Update module and site id in temporary visit table
WITH sites AS (
    SELECT
        id_base_site AS id,
        base_site_code::int AS site_code
    FROM gn_monitoring.t_base_sites
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET site_id = sites.id
FROM sites
WHERE vt.site_code = sites.site_code;

-- Update visit, dataset, module and meshe id in temporary visit table
WITH visits AS (
    SELECT
        bv.id_base_visit AS id,
        bv.id_base_site AS id_site,
        bv.id_dataset,
        bv.id_module,
        bv.uuid_base_visit AS uuid,
        bv.visit_date_min AS date_min,
        bv.visit_date_max AS date_max,
        a.id_area,
        a.area_code
    FROM gn_monitoring.t_base_visits AS bv
        JOIN gn_monitoring.cor_site_area AS sa
            ON (bv.id_base_site = sa.id_base_site)
        JOIN ref_geo.l_areas AS a
            ON (sa.id_area = a.id_area)
        JOIN ref_geo.bib_areas_types AS bat
            ON (a.id_type = bat.id_type)
    WHERE bat.type_code ILIKE :'meshesCode'
)
UPDATE :moduleSchema.:visitsTmpTable AS vt
SET
    visit_id = v.id,
    visit_uuid = v.uuid,
    module_id = v.id_module,
    dataset_id = v.id_dataset,
    meshe_id = v.id_area
FROM visits AS v
WHERE vt.site_id = v.id_site
    AND vt.meshe_code = v.area_code
    AND vt.date_min = v.date_min
    AND vt.date_max = v.date_max ;


-- Update organism and role id in temporary observers table
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


-- Update roles added with current import only
-- TODO: find a better way to mark users added by current import
WITH users AS (
    SELECT
        r.id_role AS id
    FROM utilisateurs.t_roles AS r
        JOIN utilisateurs.cor_role_liste AS rl
            ON (r.id_role = rl.id_role)
    WHERE r.identifiant IS NULL
        AND r.active = False
        AND champs_addi @> json_build_object('sft', json_build_object('importDate', :'importDate'))::jsonb
        AND rl.id_liste = :'observersListId'
)
UPDATE :moduleSchema.:visitsObserversTmpTable AS ot
SET role_added = True
FROM users AS u
WHERE u.id = ot.role_id ;


-- Update organisms added with current import only
-- TODO: find a better way to mark organism added by current import
WITH not_added_organisms AS (
    SELECT DISTINCT id_organisme AS id
    FROM utilisateurs.t_roles
    WHERE id_organisme IS NOT NULL
		AND (
			active = True
	        OR NOT(champs_addi @> json_build_object('sft', json_build_object('importDate', :'importDate'))::jsonb)
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

COMMIT;

BEGIN;

-- DELETE FROM cor_visit_grid
DELETE FROM :moduleSchema.cor_visit_grid
USING :moduleSchema.:visitsTmpTable AS vt
WHERE id_base_visit = vt.visit_id
    AND id_area = vt.meshe_id;

-- DELETE FROM gn_monitoring.cor_visit_observer
DELETE FROM gn_monitoring.cor_visit_observer AS o
WHERE EXISTS (
    SELECT DISTINCT vt.visit_id, vo.role_id
    FROM :moduleSchema.:visitsTmpTable AS vt
        JOIN :moduleSchema.:visitsHasObserversTmpTable AS vho
            ON (vt.id_visit_meshe = vho.id_visit_meshe)
        JOIN :moduleSchema.:visitsObserversTmpTable AS vo
            ON (vho.id_observer = vo.id_observer)
    WHERE vt.visit_id = o.id_base_visit
        AND vo.role_id = o.id_role
);

-- DELETE FROM utilisateurs.cor_role_list
DELETE FROM utilisateurs.cor_role_liste
USING :moduleSchema.:visitsObserversTmpTable AS o
WHERE id_role = o.role_id
    AND id_liste = :'observersListId'
    AND o.role_added = True;

-- DELETE FROM utilisateurs.t_roles
DELETE FROM utilisateurs.t_roles
USING :moduleSchema.:visitsObserversTmpTable AS vo
WHERE id_role = vo.role_id
    AND role_added = True ;

-- DELETE FROM utilisateurs.bib_organismes
DELETE FROM utilisateurs.bib_organismes
USING :moduleSchema.:visitsObserversTmpTable AS vo
WHERE id_organisme = vo.organism_id
    AND organism_added = True ;

-- DELETE FROM gn_monitoring.t_base_visits
DELETE FROM gn_monitoring.t_base_visits
USING :moduleSchema.:visitsTmpTable AS vt
WHERE id_base_visit = vt.visit_id ;

COMMIT;

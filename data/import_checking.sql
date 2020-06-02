\echo 'Number of sites by dates:'
SELECT bs.first_use_date, COUNT(bs.id_base_site) AS sites_total
FROM gn_monitoring.t_base_sites AS bs
    JOIN gn_monitoring.cor_site_module AS sm
        ON (bs.id_base_site = sm.id_base_site)
WHERE id_module = (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE :'moduleCode'
)
GROUP BY bs.first_use_date
ORDER BY bs.first_use_date DESC;


\echo 'Number of meshes by sites dates:'
SELECT bs.first_use_date, COUNT(a.id_area) AS meshes_total
FROM gn_monitoring.t_base_sites AS bs
    JOIN gn_monitoring.cor_site_module AS sm
        ON (bs.id_base_site = sm.id_base_site)
    JOIN gn_monitoring.cor_site_area AS sa
        ON (bs.id_base_site = sa.id_base_site)
    JOIN ref_geo.l_areas AS a
        ON (sa.id_area = a.id_area)
    JOIN ref_geo.bib_areas_types AS bat
        ON (a.id_type = bat.id_type)
WHERE id_module = (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE :'moduleCode'
)
    AND bat.type_code ILIKE :'meshesCode'
GROUP BY bs.first_use_date
ORDER BY bs.first_use_date DESC;


\echo 'Number of meshes:'
SELECT COUNT(a.id_area) AS meshes_total
FROM gn_monitoring.cor_site_module AS sm
    JOIN gn_monitoring.cor_site_area AS sa
        ON (sm.id_base_site = sa.id_base_site)
    JOIN ref_geo.l_areas AS a
        ON (sa.id_area = a.id_area)
    JOIN ref_geo.bib_areas_types AS bat
        ON (a.id_type = bat.id_type)
WHERE id_module = (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE :'moduleCode'
)
    AND bat.type_code ILIKE :'meshesCode' ;

\echo 'Number of distinct meshes:'
WITH distinct_meshes_nb AS (
	SELECT COUNT(*) AS counter
	FROM gn_monitoring.cor_site_module AS sm
	    JOIN gn_monitoring.cor_site_area AS sa
	        ON (sm.id_base_site = sa.id_base_site)
	    JOIN ref_geo.l_areas AS a
	        ON (sa.id_area = a.id_area)
	    JOIN ref_geo.bib_areas_types AS bat
	        ON (a.id_type = bat.id_type)
	WHERE sm.id_module = (
	    SELECT id_module
	    FROM gn_commons.t_modules
	    WHERE module_code ILIKE :'moduleCode'
	)
	    AND bat.type_code ILIKE :'meshesCode'
	GROUP BY a.id_area
	HAVING COUNT(a.id_area) = 1
)
SELECT COUNT(*) AS distinct_meshes_total
FROM distinct_meshes_nb;


\echo 'Number of sites by taxon'
SELECT s.cd_nom, t.nom_valide, COUNT(*) AS nb_sites
FROM :moduleSchema.t_infos_site AS s
    JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
GROUP BY s.cd_nom, t.nom_valide
ORDER BY t.nom_valide ;


\echo 'Number of visits by taxon'
SELECT s.cd_nom, t.nom_valide, COUNT(*) AS nb_visites
FROM gn_monitoring.t_base_visits AS v
    JOIN :moduleSchema.t_infos_site AS s
        ON s.id_base_site = v.id_base_site
    JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
GROUP BY s.cd_nom, t.nom_valide
ORDER BY t.nom_valide ;


\echo 'Number of visited meshes by taxon'
SELECT s.cd_nom, t.nom_valide, COUNT(*) AS nb_mailles_visitees
FROM :moduleSchema.cor_visit_grid AS cv
    JOIN gn_monitoring.t_base_visits AS v
        ON v.id_base_visit = cv.id_base_visit
    JOIN :moduleSchema.t_infos_site AS s
        ON s.id_base_site = v.id_base_site
    JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
GROUP BY s.cd_nom, t.nom_valide
ORDER BY t.nom_valide ;

\echo 'Number of unvisited meshes by taxon'
WITH sft_module AS (
	SELECT id_module
	FROM gn_commons.t_modules
	WHERE module_code ILIKE :'moduleCode'
	LIMIT 1
)
SELECT tis.cd_nom, t.nom_valide, COUNT(*) AS nb_mailles_non_visitees
FROM sft_module, gn_monitoring.t_base_sites AS tbs
	JOIN gn_monitoring.cor_site_module AS sm
		ON (sm.id_base_site = tbs.id_base_site)
    JOIN gn_monitoring.cor_site_area AS csa
	    ON (csa.id_base_site = tbs.id_base_site)
    JOIN ref_geo.l_areas AS a
        ON (csa.id_area = a.id_area)
    JOIN ref_geo.bib_areas_types AS bat
	    ON (a.id_type = bat.id_type)
    JOIN :moduleSchema.t_infos_site AS tis
    	ON (tbs.id_base_site = tis.id_base_site)
   	JOIN taxonomie.taxref AS t
        ON (t.cd_nom = tis.cd_nom)
WHERE bat.type_code ILIKE :'meshesCode'
	AND sm.id_module = sft_module.id_module
	AND NOT EXISTS (
		SELECT 'X' -- SELECT list mostly irrelevant; can just be empty in Postgres
		FROM :moduleSchema.cor_visit_grid AS cv
			JOIN gn_monitoring.t_base_visits AS v
		        ON (v.id_base_visit = cv.id_base_visit)
		WHERE cv.id_area = a.id_area
			AND v.id_base_site = tbs.id_base_site
	)
GROUP BY tis.cd_nom, t.nom_valide
ORDER BY t.nom_valide ;

\echo 'Number of persences/absences by taxon'
SELECT s.cd_nom, t.nom_valide, cv.presence, COUNT(*) AS nb_presence
FROM :moduleSchema.cor_visit_grid AS cv
    JOIN gn_monitoring.t_base_visits AS v
        ON v.id_base_visit = cv.id_base_visit
    JOIN :moduleSchema.t_infos_site AS s
        ON s.id_base_site = v.id_base_site
    JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
GROUP BY s.cd_nom, t.nom_valide, cv.presence
ORDER BY t.nom_valide ;

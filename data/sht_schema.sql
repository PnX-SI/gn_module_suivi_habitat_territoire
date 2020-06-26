BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Set database variables'
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

\echo '--------------------------------------------------------------------------------'
\echo 'Create SHT schema'
CREATE SCHEMA :moduleSchema;

\echo '--------------------------------------------------------------------------------'
\echo 'Set new database variables'
SET search_path = :moduleSchema, pg_catalog, public;
SET default_with_oids = false;

\echo '--------------------------------------------------------------------------------'
\echo 'TABLES'

\echo 'Table `t_infos_site`'
CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_hab integer NOT NULL
);
COMMENT ON TABLE :moduleSchema.t_infos_site IS
    'Extension de t_base_sites de gn_monitoring, permet d''avoir les infos complémentaires d''un site';


\echo 'Table `cor_visit_taxons`'
CREATE TABLE cor_visit_taxons (
    id_cor_visite_taxons serial NOT NULL,
    id_base_visit integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE :moduleSchema.cor_visit_taxons IS
    'Enregistrer la présence d''un taxon dans une maille définie lors d''une visite';


\echo 'Table `cor_visit_perturbation`'
CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL,
    create_date timestamp without time zone NOT NULL
);
COMMENT ON TABLE :moduleSchema.cor_visit_perturbation IS
    'Enregistrer les perturbations constatées lors d''une visite';


\echo 'Table `cor_habitat_taxon`'
CREATE TABLE cor_habitat_taxon (
    id_cor_habitat_taxon serial NOT NULL,
    id_habitat integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE :moduleSchema.cor_visit_perturbation IS
    'Enregistrer les taxons de chaque habitat';


\echo 'Add primary keys on previous tables'
ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT pk_id_t_infos_site
    PRIMARY KEY (id_infos_site);

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT pk_cor_visit_taxons
    PRIMARY KEY (id_cor_visite_taxons);

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT pk_cor_visit_perturbation
    PRIMARY KEY (id_base_visit, id_nomenclature_perturbation);

ALTER TABLE ONLY cor_habitat_taxon
    ADD CONSTRAINT pk_cor_habitat_taxon
    PRIMARY KEY (id_cor_habitat_taxon);


\echo '--------------------------------------------------------------------------------'
\echo 'FOREIGN KEYS'

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_id_base_site
    FOREIGN KEY (id_base_site)
    REFERENCES gn_monitoring.t_base_sites (id_base_site)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_cd_hab
    FOREIGN KEY (cd_hab)
    REFERENCES ref_habitats.habref (cd_hab)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT fk_cor_visit_taxons_id_base_visit
    FOREIGN KEY (id_base_visit)
    REFERENCES gn_monitoring.t_base_visits (id_base_visit)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT fk_cor_visit_taxons_cd_nom
    FOREIGN KEY (cd_nom)
    REFERENCES taxonomie.taxref (cd_nom);

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit
    FOREIGN KEY (id_base_visit)
    REFERENCES gn_monitoring.t_base_visits (id_base_visit)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation
    FOREIGN KEY (id_nomenclature_perturbation)
    REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_habitat_taxon
    ADD CONSTRAINT fk_cor_habitat_taxon_id_habitat
    FOREIGN KEY (id_habitat)
    REFERENCES ref_habitats.habref (cd_hab)
    ON UPDATE CASCADE;

ALTER TABLE ONLY cor_habitat_taxon
    ADD CONSTRAINT fk_cor_habitat_taxon_cd_nom
    FOREIGN KEY (cd_nom)
    REFERENCES taxonomie.taxref (cd_nom)
    ON UPDATE CASCADE;


\echo '--------------------------------------------------------------------------------'
\echo 'UNIQUE CONSTRAINTS'

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT unique_cor_visit_taxons UNIQUE ( id_base_visit, cd_nom );


\echo '--------------------------------------------------------------------------------'
\echo 'VIEWS'

\echo 'Create view to export visits'
CREATE OR REPLACE VIEW :moduleSchema.export_visits AS WITH
observers AS(
    SELECT
        v.id_base_visit,
        string_agg(roles.nom_role::text || ' ' || roles.prenom_role::text, ',') AS observateurs,
        string_agg(roles.id_organisme::text, ',' ) AS organisme
    FROM gn_monitoring.t_base_visits v
        JOIN gn_monitoring.cor_visit_observer observer
            ON observer.id_base_visit = v.id_base_visit
        JOIN utilisateurs.t_roles roles
            ON roles.id_role = observer.id_role
    GROUP BY v.id_base_visit
),
perturbations AS(
    SELECT
        v.id_base_visit,
        string_agg(n.label_default, ',') AS label_perturbation
    FROM gn_monitoring.t_base_visits v
        JOIN :moduleSchema.cor_visit_perturbation p
            ON v.id_base_visit = p.id_base_visit
        JOIN ref_nomenclatures.t_nomenclatures n
            ON p.id_nomenclature_perturbation = n.id_nomenclature
    GROUP BY v.id_base_visit
),
area AS(
    SELECT
        bs.id_base_site,
        a.id_area,
        a.area_name
    FROM ref_geo.l_areas a
        JOIN gn_monitoring.t_base_sites bs
            ON a.area_name = bs.base_site_code
),
taxons AS (
    SELECT v.id_base_visit,
        json_object_agg(
            tr.lb_nom,
            CASE tr.lb_nom
            WHEN tr.lb_nom
            THEN True
            END ORDER BY tr.lb_nom
        ) AS nom_valide_taxon,
        string_agg(tr.cd_nom::text, ',') AS cover_cdnom
    FROM gn_monitoring.t_base_visits v
        JOIN :moduleSchema.cor_visit_taxons t
            ON t.id_base_visit = v.id_base_visit
        JOIN taxonomie.taxref tr
            ON t.cd_nom = tr.cd_nom
    GROUP BY v.id_base_visit
)
-- All the meshes of a site with their visits
SELECT sites.id_base_site AS idbsite,
	cor.id_area AS idarea,
	visits.id_base_visit AS idbvisit,
	visits.visit_date_min AS visitdate,
	visits.comments,
	ar.geom,
	per.label_perturbation AS lbperturb,
	obs.observateurs AS observers,
	obs.organisme,
	tax.nom_valide_taxon AS nomvtaxon,
    tax.cover_cdnom AS covtaxons,
	sites.base_site_name AS bsitename,
	habref.lb_hab_fr AS lbhab,
	habref.cd_hab,
	area.area_name,
	ar.id_type,
    bat.type_name
FROM gn_monitoring.t_base_sites sites
    JOIN gn_monitoring.cor_site_area cor
        ON cor.id_base_site = sites.id_base_site
    JOIN gn_monitoring.t_base_visits visits
        ON sites.id_base_site = visits.id_base_site
    JOIN taxons tax
        ON tax.id_base_visit = visits.id_base_visit
    JOIN observers obs
        ON obs.id_base_visit = visits.id_base_visit
    LEFT JOIN perturbations per
        ON per.id_base_visit = visits.id_base_visit
    JOIN area
        ON area.id_base_site = sites.id_base_site
    JOIN :moduleSchema.t_infos_site info
        ON info.id_base_site = sites.id_base_site
    JOIN ref_habitats.habref habref
        ON habref.cd_hab = info.cd_hab
    JOIN ref_geo.l_areas ar
        ON ar.id_area = cor.id_area
    JOIN ref_geo.li_grids lg
        ON ar.id_area = lg.id_area
    JOIN ref_geo.bib_areas_types bat
        ON ar.id_type = bat.id_type
ORDER BY visits.id_base_visit;

-- ----------------------------------------------------------------------------
COMMIT;

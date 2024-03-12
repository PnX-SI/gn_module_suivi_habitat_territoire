
-- -----------------------------------------------------------------------------
-- Set database variables
SET client_encoding = 'UTF8';

-- -----------------------------------------------------------------------------
-- Create SHT schema
CREATE SCHEMA pr_monitoring_habitat_territory;

-- -----------------------------------------------------------------------------
-- Set new database variables
SET search_path = pr_monitoring_habitat_territory, pg_catalog, public;
SET default_with_oids = false;

-- -----------------------------------------------------------------------------
-- TABLES

-- Table `t_infos_site`
CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_hab integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.t_infos_site IS
    'Extension de t_base_sites de gn_monitoring, permet d''avoir les infos complémentaires d''un site';


-- 'Table `cor_visit_taxons`
CREATE TABLE cor_visit_taxons (
    id_cor_visite_taxons serial NOT NULL,
    id_base_visit integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_taxons IS
    'Enregistrer la présence d''un taxon dans une maille définie lors d''une visite';


--  'Table `cor_visit_perturbation`
CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL,
    create_date timestamp without time zone NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_perturbation IS
    'Enregistrer les perturbations constatées lors d''une visite';


--  'Table `cor_habitat_taxon`
CREATE TABLE cor_habitat_taxon (
    id_cor_habitat_taxon serial NOT NULL,
    id_habitat integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_perturbation IS
    'Enregistrer les taxons de chaque habitat';


--  'Add primary keys on previous tables'
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


-- -----------------------------------------------------------------------------
-- FOREIGN KEYS

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


-- -----------------------------------------------------------------------------
-- UNIQUE CONSTRAINTS

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT unique_cor_visit_taxons UNIQUE ( id_base_visit, cd_nom );


-- -----------------------------------------------------------------------------
-- VIEWS

-- Create view to export visits
CREATE OR REPLACE VIEW pr_monitoring_habitat_territory.export_visits AS
    WITH observers AS(
        SELECT
            v.id_base_visit,
            string_agg(roles.nom_role || ' ' || roles.prenom_role, ', ') AS observers,
            string_agg(org.nom_organisme, ', ' ) AS organisms
        FROM gn_monitoring.t_base_visits AS v
            JOIN gn_monitoring.cor_visit_observer AS observer
                ON observer.id_base_visit = v.id_base_visit
            JOIN utilisateurs.t_roles AS roles
                ON roles.id_role = observer.id_role
            JOIN utilisateurs.bib_organismes AS org
                ON roles.id_organisme = org.id_organisme
            JOIN gn_monitoring.cor_site_module AS csm
                ON (
                    csm.id_base_site = v.id_base_site
                    AND csm.id_module = gn_commons.get_id_module_bycode('SHT')
                )
        GROUP BY v.id_base_visit
    ),
    perturbations AS(
        SELECT
            v.id_base_visit,
            string_agg(n.label_default, ', ') AS perturbations
        FROM gn_monitoring.t_base_visits v
            JOIN pr_monitoring_habitat_territory.cor_visit_perturbation AS p
                ON v.id_base_visit = p.id_base_visit
            JOIN ref_nomenclatures.t_nomenclatures AS n
                ON p.id_nomenclature_perturbation = n.id_nomenclature
            JOIN gn_monitoring.cor_site_module AS csm
                ON (
                    csm.id_base_site = v.id_base_site
                    AND csm.id_module = gn_commons.get_id_module_bycode('SHT')
                )
        GROUP BY v.id_base_visit
    ),
    taxons AS (
        SELECT v.id_base_visit,
            json_object_agg(
                tr.lb_nom,
                CASE tr.lb_nom
                WHEN tr.lb_nom
                THEN True
                END ORDER BY tr.lb_nom
            ) AS taxons_scinames,
            string_agg(tr.cd_nom::text, ', ') AS taxons_scinames_codes
        FROM gn_monitoring.t_base_visits AS v
            JOIN pr_monitoring_habitat_territory.cor_visit_taxons AS t
                ON t.id_base_visit = v.id_base_visit
            JOIN taxonomie.taxref AS tr
                ON t.cd_nom = tr.cd_nom
            JOIN gn_monitoring.cor_site_module AS csm
                ON (
                    csm.id_base_site = v.id_base_site
                    AND csm.id_module = gn_commons.get_id_module_bycode('SHT')
                )
        GROUP BY v.id_base_visit
    ),
    municipalities AS (
        SELECT
            v.id_base_visit,
            string_agg(
                areas.area_name || ' (' || areas.area_code || ')' ,
                ', '
            ) FILTER (WHERE areas.area_name IS NOT NULL) AS municipalities
        FROM gn_monitoring.t_base_visits AS v
            JOIN gn_monitoring.cor_site_module AS csm
                ON (
                    csm.id_base_site = v.id_base_site
                    AND csm.id_module = gn_commons.get_id_module_bycode('SHT')
                )
            LEFT JOIN gn_monitoring.cor_site_area AS csa
                ON csa.id_base_site = v.id_base_site
            LEFT JOIN ref_geo.l_areas AS areas
                ON (areas.id_area = csa.id_area AND areas.id_type = ref_geo.get_id_area_type('COM'))
        GROUP BY v.id_base_visit
    )
    SELECT
        visits.id_base_visit AS id_base_visit,
        visits.visit_date_min AS visit_date,
        visits.comments AS visit_comment,
        sites.id_base_site AS id_base_site,
        sites.base_site_name AS base_site_name,
        sites.base_site_code AS base_site_code,
        sites.uuid_base_site AS base_site_uuid,
        sites.geom_local AS geom,
        public.ST_AsGeoJSON(sites.geom) AS geojson,
        habref.lb_hab_fr AS habitat_name,
        habref.cd_hab AS habitat_code,
        mun.municipalities,
        per.perturbations,
        obs.observers,
        obs.organisms,
        tax.taxons_scinames,
        tax.taxons_scinames_codes
    FROM gn_monitoring.t_base_visits AS visits
        LEFT JOIN gn_monitoring.t_base_sites AS sites
            ON sites.id_base_site = visits.id_base_site
        LEFT JOIN pr_monitoring_habitat_territory.t_infos_site AS infos_sites
            ON infos_sites.id_base_site = sites.id_base_site
        LEFT JOIN ref_habitats.habref AS habref
            ON habref.cd_hab = infos_sites.cd_hab
        LEFT JOIN municipalities AS mun
            ON mun.id_base_visit = visits.id_base_visit
        LEFT JOIN taxons AS tax
            ON tax.id_base_visit = visits.id_base_visit
        LEFT JOIN observers AS obs
            ON obs.id_base_visit = visits.id_base_visit
        LEFT JOIN perturbations AS per
            ON per.id_base_visit = visits.id_base_visit
    ORDER BY visits.visit_date_min DESC, visits.id_base_visit ASC ;



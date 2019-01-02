SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA pr_monitoring_habitat_territory;

SET search_path = pr_monitoring_habitat_territory, pg_catalog, public;

SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_infos_site (
    id_infos_site serial NOT NULL,
    id_base_site integer NOT NULL,
    cd_hab integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.t_infos_site IS 'Extension de t_base_sites de gn_monitoring, permet d\avoir les infos complémentaires d\un site';


CREATE TABLE cor_visit_taxons (
    id_cor_visite_taxons serial NOT NULL,
    id_base_visit integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_taxons IS 'Enregistrer la présence d\une espèce dans une maille définie lors d\une visite';


CREATE TABLE cor_visit_perturbation (
    id_base_visit integer NOT NULL,
    id_nomenclature_perturbation integer NOT NULL,
    create_date timestamp without time zone NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_perturbation IS 'Enregistrer les perturbations constatées lors d\une visite';


CREATE TABLE cor_habitat_taxon (
    id_cor_habitat_taxon serial NOT NULL,
    id_habitat integer NOT NULL,
    cd_nom integer NOT NULL
);
COMMENT ON TABLE pr_monitoring_habitat_territory.cor_visit_perturbation IS 'Enregistrer les taxons de chaque habitat';


ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT pk_id_t_infos_site PRIMARY KEY (id_infos_site);

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT pk_cor_visit_taxons PRIMARY KEY (id_cor_visite_taxons);

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT pk_cor_visit_perturbation PRIMARY KEY (id_base_visit, id_nomenclature_perturbation);

ALTER TABLE ONLY cor_habitat_taxon 
    ADD CONSTRAINT pk_cor_habitat_taxon PRIMARY KEY (id_cor_habitat_taxon);



---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY t_infos_site 
    ADD CONSTRAINT fk_t_infos_site_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE; 

ALTER TABLE ONLY t_infos_site
    ADD CONSTRAINT fk_t_infos_site_cd_hab FOREIGN KEY (cd_hab) REFERENCES habitat.habref (cd_hab) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT fk_cor_visit_taxons_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_visit_taxons
    ADD CONSTRAINT fk_cor_visit_taxons_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref (cd_nom);


ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits (id_base_visit) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_visit_perturbation 
    ADD CONSTRAINT fk_cor_visit_perturbation_id_nomenclature_perturbation FOREIGN KEY (id_nomenclature_perturbation) REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_habitat_taxon 
    ADD CONSTRAINT fk_cor_habitat_taxon_id_habitat FOREIGN KEY (id_habitat) REFERENCES habitat.habref (cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_habitat_taxon 
    ADD CONSTRAINT fk_cor_habitat_taxon_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref (cd_nom) ON UPDATE CASCADE;


--------------
-- DATA -----
--------------
-- TODO : Y'a t-il déjà tous les cdnom embarqués dans geonature
-- si c'est le cas insérer en fonction du cdnom dans la table cor_habitat_taxon



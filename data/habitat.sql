SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA ref_habitat;

SET search_path = ref_habitat, pg_catalog, public;

SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

-- init référentiel HABREF 4.0, table TYPOREF
CREATE TABLE typoref (
    cd_typo serial NOT NULL,
    cd_table character varying(255),
    lb_nom_typo character varying(100),
    nom_jeu_donnees character varying(255),
    date_creation character varying(255),
    date_mise_jour_table character varying(255),
    date_mise_jour_metadonnees character varying(255),
    auteur_typo character varying(4000),
    auteur_table character varying(4000),
    territoire character varying(4000),
    organisme character varying(255),
    langue character varying(255),
    presentation character varying(4000)
);
COMMENT ON TABLE ref_habitat.typoref IS 'typoref, extrait de la table TYPOREF du référentiel HABREF 4.0';

-- init référentiel HABREF 4.0, table HABREF
CREATE TABLE habref (
    cd_hab serial NOT NULL,
    fg_validite character varying(20) NOT NULL,
    cd_typo integer NOT NULL,
    lb_code character varying(50),
    lb_hab_fr character varying(255),
    lb_hab_fr_complet character varying(255),
    lb_hab_en character varying(255),
    lb_auteur character varying(255),
    niveau integer,
    lb_niveau character varying(100),
    cd_hab_sup integer NOT NULL,
    path_cd_hab character varying(2000),
    france character varying(5),
    lb_description character varying(4000)
);
COMMENT ON TABLE ref_habitat.habref IS 'habref, extrait de la table HABREF référentiel HABREF 4.0 INPN';

CREATE TABLE bib_list_habitat (
    id_list serial NOT NULL,
    list_name character varying(255) NOT NULL
);
COMMENT ON TABLE ref_habitat.bib_list_habitat IS 'Table des listes des habitats';

CREATE TABLE cor_list_habitat (
    id_cor_list serial NOT NULL,
    id_list integer NOT NULL,
    cd_hab integer NOT NULL
);
COMMENT ON TABLE ref_habitat.cor_list_habitat IS 'Habitat de chaque liste';


ALTER TABLE ONLY typoref
    ADD CONSTRAINT pk_typoref PRIMARY KEY (cd_typo);

ALTER TABLE ONLY habref 
    ADD CONSTRAINT pk_habref PRIMARY KEY (cd_hab);

ALTER TABLE ONLY bib_list_habitat 
    ADD CONSTRAINT pk_bib_list_habitat PRIMARY KEY (id_list);

ALTER TABLE ONLY cor_list_habitat 
    ADD CONSTRAINT pk_cor_list_habitat PRIMARY KEY (id_cor_list);

---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY habref 
    ADD CONSTRAINT fk_typoref FOREIGN KEY (cd_typo) REFERENCES ref_habitat.typoref (cd_typo) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitat.habref (cd_hab) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_id_list FOREIGN KEY (id_list) REFERENCES ref_habitat.bib_list_habitat (id_list) ON UPDATE CASCADE ON DELETE CASCADE;


----------
--UNIQUE--
----------

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT unique_cor_list_habitat UNIQUE ( id_list, cd_hab );

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA IF NOT EXISTS ref_habitat;

SET search_path = ref_habitat, pg_catalog, public;

SET default_with_oids = false;

----------
--TABLES--
----------
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
    presentation character varying(4000),
    description character varying(4000),
    origine character varying(4000),
    ref_biblio character varying(4000),
    mots_cles character varying(255),
    referencement character varying(4000),
    diffusion character varying(4000), -- pas de doc
    derniere_modif character varying(4000),
    type_table character varying(6),
    cd_typo_entre integer,
    cd_typo_sortie integer,
    niveau_inpn character varying(255) -- pas de doc
);
COMMENT ON TABLE ref_habitat.typoref IS 'typoref, table TYPOREF du référentiel HABREF 4.0';

-- init référentiel HABREF 4.0, table HABREF
CREATE TABLE habref (
    cd_hab serial NOT NULL,
    fg_validite character varying(20) NOT NULL,
    cd_typo integer NOT NULL,
    lb_code character varying(50),
    lb_hab_fr character varying(500),
    lb_hab_fr_complet character varying(500),
    lb_hab_en character varying(500),
    lb_auteur character varying(500),
    niveau integer,
    lb_niveau character varying(100),
    cd_hab_sup integer,
    path_cd_hab character varying(2000),
    france character varying(5),
    lb_description character varying(4000)
);
COMMENT ON TABLE ref_habitat.habref IS 'habref, table HABREF référentiel HABREF 4.0 INPN';


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY typoref
    ADD CONSTRAINT pk_typoref PRIMARY KEY (cd_typo);

ALTER TABLE ONLY habref 
    ADD CONSTRAINT pk_habref PRIMARY KEY (cd_hab);

---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY habref 
    ADD CONSTRAINT fk_typoref FOREIGN KEY (cd_typo) REFERENCES ref_habitat.typoref (cd_typo) ON UPDATE CASCADE;

---------
--INDEX--
---------
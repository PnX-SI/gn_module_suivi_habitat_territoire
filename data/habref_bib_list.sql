SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = ref_habitat, pg_catalog, public;

SET default_with_oids = false;

----------
--TABLES--
----------

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

---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY bib_list_habitat 
    ADD CONSTRAINT pk_bib_list_habitat PRIMARY KEY (id_list);

ALTER TABLE ONLY cor_list_habitat 
    ADD CONSTRAINT pk_cor_list_habitat PRIMARY KEY (id_cor_list);

---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitat.habref (cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT fk_cor_list_habitat_id_list FOREIGN KEY (id_list) REFERENCES ref_habitat.bib_list_habitat (id_list) ON UPDATE CASCADE;


----------
--UNIQUE--
----------

ALTER TABLE ONLY cor_list_habitat
    ADD CONSTRAINT unique_cor_list_habitat UNIQUE ( id_list, cd_hab );

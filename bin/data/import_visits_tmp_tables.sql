-- Script SQL to create temporary tables for visits import
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Add function get_id_observer_tmp()'
CREATE OR REPLACE FUNCTION :moduleSchema.get_id_observer_tmp(moduleSchema TEXT, visitsObserversTmpTable TEXT, md5Sum character varying)
    RETURNS int AS
$BODY$
DECLARE idObserver INTEGER;
BEGIN
    -- Function which return the id_observer from a md5 sum of lower case lastanme then firstname concatenate by "_"
    EXECUTE format(
            'SELECT id_observer
            FROM %1$I.%2$I
            WHERE md5 = %3$L
            LIMIT 1',
            moduleSchema, visitsObserversTmpTable, md5Sum)
        INTO idObserver;
    RETURN idObserver;
END;
$BODY$
    LANGUAGE plpgsql IMMUTABLE;


\echo '--------------------------------------------------------------------------------'
\echo 'Clean tables if necessary'
DROP TABLE IF EXISTS :moduleSchema.:visitsHasPerturbationsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsHasObserversTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:obsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsObserversTmpTable;


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store meshes taxon presence information for each visit'
CREATE TABLE :moduleSchema.:visitsTmpTable (
	id_visit serial NOT NULL,
	site_code varchar(50) NOT NULL,
    site_id int4 NULL,
    module_id int4 NULL,
    dataset_id int4 NULL,
    visit_code varchar(50) NOT NULL,
    visit_id int4 NULL,
    visit_uuid uuid NULL,
	date_min date NOT NULL,
	date_max date NULL,
	meshe_code varchar(50) NULL,
    meshe_id int4 NULL,
    observers varchar(250) NULL,
    organisms varchar(250) NULL,
    comment text NULL,
    perturbations varchar(250) NULL,
    CONSTRAINT pk_:visitsTmpTable PRIMARY KEY (id_visit)
);


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store link between visit and perturbations nomenclatures'
CREATE TABLE :moduleSchema.:visitsHasPerturbationsTmpTable (
	id_visit int4 NOT NULL,
	id_nomenclature_perturbation int4 NOT NULL,
	CONSTRAINT pk_:visitsHasPerturbationsTmpTable PRIMARY KEY (id_visit, id_nomenclature_perturbation)
);


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store link between meshes visit and observers'
CREATE TABLE :moduleSchema.:visitsHasObserversTmpTable (
	id_visit int4 NOT NULL,
	id_observer int4 NOT NULL,
	CONSTRAINT pk_:visitsHasObserversTmpTable PRIMARY KEY (id_visit, id_observer)
);


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store observers & organisms data'
CREATE TABLE :moduleSchema.:visitsObserversTmpTable (
	id_observer serial NOT NULL,
    md5 varchar(100) NOT NULL,
    fullname varchar(100) NULL,
	firstname varchar(100) NOT NULL,
    lastname varchar(100) NOT NULL,
	organism varchar(100) NULL,
	role_id int4 NULL,
    role_added bool NULL,
    organism_id int4 NULL,
    organism_added bool NULL,
    CONSTRAINT pk_:visitsObserversTmpTable PRIMARY KEY (id_observer)
);
COMMENT ON COLUMN :moduleSchema.:visitsObserversTmpTable.role_added IS
    'Use to delete only added roles.';
COMMENT ON COLUMN :moduleSchema.:visitsObserversTmpTable.organism_added IS
    'Use to delete only added organisms.';


\echo '--------------------------------------------------------------------------------'
\echo 'Add foreign keys after creating tables'
ALTER TABLE :moduleSchema.:visitsHasObserversTmpTable
    ADD CONSTRAINT fk_vho_visit
    FOREIGN KEY (id_visit)
    REFERENCES :moduleSchema.:visitsTmpTable(id_visit);
ALTER TABLE :moduleSchema.:visitsHasObserversTmpTable
    ADD CONSTRAINT fk_vho_observer
    FOREIGN KEY (id_observer)
    REFERENCES :moduleSchema.:visitsObserversTmpTable(id_observer);


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

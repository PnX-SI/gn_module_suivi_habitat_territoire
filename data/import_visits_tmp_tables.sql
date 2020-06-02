-- Script SQL to create temporary tables for visits import
BEGIN;

-- Function which return the id_observer from a md5 sum of lower case lastanme then firstname concatenate by "_"
CREATE OR REPLACE FUNCTION :moduleSchema.get_id_observer_tmp(moduleSchema TEXT, visitsObserversTmpTable TEXT, md5Sum character varying)
    RETURNS int AS
$BODY$
DECLARE idObserver INTEGER;
BEGIN
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


-- Clean tables if necessary
DROP TABLE IF EXISTS :moduleSchema.:visitsHasObserversTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsObserversTmpTable;


-- Temporary table to store meshes taxon presence information for each visit
CREATE TABLE :moduleSchema.:visitsTmpTable (
	id_visit_meshe serial NOT NULL,
	site_code int4 NULL,
    site_id int4 NULL,
    module_id int4 NULL,
    dataset_id int4 NULL,
    visit_id int4 NULL,
    visit_uuid uuid NULL,
	date_min date NOT NULL,
	date_max date NULL,
	meshe_code varchar(20) NOT NULL,
    meshe_id int4 NULL,
    observers varchar(250) NULL,
    organisms varchar(250) NULL,
	presence varchar(2) NOT NULL,
    CONSTRAINT pk_:visitsTmpTable PRIMARY KEY (id_visit_meshe)
);


-- Temporary table to store link between meshes visit and observers
CREATE TABLE :moduleSchema.:visitsHasObserversTmpTable (
	id_visit_meshe int4 NOT NULL,
	id_observer int4 NOT NULL,
	CONSTRAINT pk_:visitsHasObserversTmpTable PRIMARY KEY (id_visit_meshe, id_observer)
);

-- Temporary table to store observers & organisms data
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

-- Add foreign keys after creating tables
ALTER TABLE :moduleSchema.:visitsHasObserversTmpTable
    ADD CONSTRAINT fk_vho_visit
    FOREIGN KEY (id_visit_meshe)
    REFERENCES :moduleSchema.:visitsTmpTable(id_visit_meshe);
ALTER TABLE :moduleSchema.:visitsHasObserversTmpTable
    ADD CONSTRAINT fk_vho_observer
    FOREIGN KEY (id_observer)
    REFERENCES :moduleSchema.:visitsObserversTmpTable(id_observer);


COMMIT;

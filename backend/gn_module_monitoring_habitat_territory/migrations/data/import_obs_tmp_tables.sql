-- Script SQL to create temporary tables for observations import
BEGIN;

\echo '--------------------------------------------------------------------------------'
\echo 'Clean tables if necessary'
DROP TABLE IF EXISTS :moduleSchema.:visitsHasPerturbationsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsHasObserversTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:visitsTmpTable;
DROP TABLE IF EXISTS :moduleSchema.:obsTmpTable;


\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store visits informations'
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
    observers varchar(250) NULL,
    organisms varchar(250) NULL,
    comment text NULL,
    perturbations varchar(250) NULL,
    CONSTRAINT pk_:visitsTmpTable PRIMARY KEY (id_visit)
);

\echo '--------------------------------------------------------------------------------'
\echo 'Temporary table to store observations information for each visit'
CREATE TABLE :moduleSchema.:obsTmpTable (
	id_obs serial NOT NULL,
    visit_code varchar(50) NOT NULL,
    visit_id int4 NULL,
    cd_nom int4 NOT NULL,
    presence boolean NOT NULL,
    CONSTRAINT pk_:obsTmpTable PRIMARY KEY (id_obs)
);


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

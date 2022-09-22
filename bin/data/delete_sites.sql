-- Script SQL to delete imported sites (use with `import_sites.sh`)
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove link between sites and the SHT module'
DELETE FROM gn_monitoring.cor_site_module
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTableTmp AS tmp
                ON (tmp.:sitesColumnCode::character varying = bs.base_site_code)
        WHERE bs.first_use_date = :'importDate'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove links between sites and areas'
DELETE FROM gn_monitoring.cor_site_area
    WHERE id_base_site IN (
        SELECT bs.id_base_site
        FROM gn_monitoring.t_base_sites AS bs
            JOIN :moduleSchema.:sitesTableTmp AS tmp
                ON (tmp.:sitesColumnCode::character varying = bs.base_site_code)
        WHERE bs.first_use_date = :'importDate'
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Remove extended site infos'
DELETE FROM :moduleSchema.t_infos_site AS tis
    WHERE EXISTS (
        SELECT 1
        FROM :moduleSchema.:sitesTableTmp AS tmp
            JOIN gn_monitoring.t_base_sites AS bs
                ON (tmp.:sitesColumnCode::character varying = bs.base_site_code)
        WHERE tis.id_base_site = bs.id_base_site
            AND tis.cd_hab = tmp.:sitesColumnHabitat::integer
            AND bs.first_use_date = :'importDate'
    );


\echo '--------------------------------------------------------------------------------'
\echo 'Remove base sites'
DELETE FROM gn_monitoring.t_base_sites
    WHERE base_site_code IN (
        SELECT :sitesColumnCode::character varying FROM :moduleSchema.:sitesTableTmp
    )
    AND first_use_date = :'importDate';


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;


-- ----------------------------------------------------------------------------
-- REF GEO
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Disable dependencies of "ref_geo.l_areas" to speed the deleting'
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities DISABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_area;
ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT fk_cor_area_taxon_id_area;
ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT fk_cor_sensitivity_area_id_area_fkey;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT fk_cor_site_area_id_area;


\echo '--------------------------------------------------------------------------------'
\echo 'Add index to speed deleting on ref_geo.l_areas'
CREATE INDEX IF NOT EXISTS index_l_areas_id_type_area_name ON ref_geo.l_areas (id_type, area_name);


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete li_grids entries'
DELETE FROM ref_geo.li_grids
    WHERE id_area IN (
        SELECT id_area
        FROM ref_geo.l_areas AS a
            JOIN :moduleSchema.:sitesTableTmp AS m
                ON (a.area_code = m.:sitesColumnCode)
        WHERE a.comment = CONCAT('SHT import date: ', :'importDate')
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete cor_site_area entries'
DELETE FROM gn_monitoring.cor_site_area
    WHERE id_area IN (
        SELECT id_area
        FROM ref_geo.l_areas AS a
            JOIN :moduleSchema.:sitesTableTmp AS m
                ON (a.area_code = m.:sitesColumnCode)
        WHERE a.comment = CONCAT('SHT import date: ', :'importDate')
    ) ;


\echo '--------------------------------------------------------------------------------'
\echo 'Delete meshes in ref_geo.l_areas'
DELETE FROM ref_geo.l_areas
    WHERE area_code IN (SELECT :sitesColumnCode FROM :moduleSchema.:sitesTableTmp)
        AND comment = CONCAT('SHT import date: ', :'importDate') ;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;


BEGIN;
\echo '--------------------------------------------------------------------------------'
\echo 'Enable constraints and triggers linked to "ref_geo.l_areas"'
ALTER TABLE ref_geo.li_municipalities ENABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.l_areas ENABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities ADD CONSTRAINT fk_li_municipalities_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE ON DELETE cascade ;
ALTER TABLE ref_geo.li_grids ADD CONSTRAINT fk_li_grids_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE CASCADE ON DELETE cascade  ;
ALTER TABLE gn_synthese.cor_area_synthese ADD CONSTRAINT fk_cor_area_synthese_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE cascade ;
ALTER TABLE gn_synthese.cor_area_taxon ADD CONSTRAINT fk_cor_area_taxon_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
    ON UPDATE cascade ;
ALTER TABLE gn_sensitivity.cor_sensitivity_area ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;
ALTER TABLE gn_monitoring.cor_site_area ADD CONSTRAINT fk_cor_site_area_id_area
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMIT if ALL is OK:'
COMMIT;

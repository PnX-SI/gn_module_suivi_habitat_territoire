-- Script SQL to import sites (use with `import_sites.sh`)
BEGIN;

-- ----------------------------------------------------------------------------
-- TMP TABLES
ALTER TABLE :moduleSchema.:sitesTableTmp
ALTER COLUMN :sitesColumnGeom TYPE geometry(MULTIPOLYGON, :sridLocal)
USING ST_Force2D(:sitesColumnGeom) ;

-- ----------------------------------------------------------------------------
-- GN_MONITORING

-- Insert data in `t_base_sites` with data in temporary table
-- WARNING: your Shape file must used the same SRID than you database (usually 2154)
INSERT INTO gn_monitoring.t_base_sites
    (id_nomenclature_type_site, base_site_name, base_site_description, base_site_code, first_use_date, geom)
    SELECT
        ref_nomenclatures.get_id_nomenclature('TYPE_SITE', :'sitesTypeCode'),
        CONCAT(:'sitesTypeCode', '-', :sitesColumnCode::character varying),
        :sitesColumnDesc,
        :sitesColumnCode,
        DATE(:'importDate'),
        ST_TRANSFORM(ST_SetSRID(:sitesColumnGeom, :sridLocal), :sridWorld)
    FROM :moduleSchema.:sitesTableTmp AS st
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_monitoring.t_base_sites AS bs
        WHERE bs.base_site_code = st.:sitesColumnCode::character varying
    ) ;
    
-- Insert into 'cor_site_application' this module monitoring sites
INSERT INTO gn_monitoring.cor_site_module (id_base_site, id_module)
    WITH
        sites AS (
            SELECT bs.id_base_site AS id
            FROM gn_monitoring.t_base_sites bs
                JOIN :moduleSchema.:sitesTableTmp AS tmp
                    ON (bs.base_site_code = tmp.:sitesColumnCode::character varying)
        ),
        module AS (
            SELECT id_module AS id
            FROM gn_commons.t_modules
            WHERE module_code ILIKE :'moduleCode'
        )
    SELECT sites.id, module.id FROM sites, module
ON CONFLICT ON CONSTRAINT pk_cor_site_module DO NOTHING ;

-- ----------------------------------------------------------------------------
-- MODULE SHT SCHEMA

-- Add extended site infos in 't_infos_sites'
INSERT INTO :moduleSchema.t_infos_site (id_base_site, cd_hab)
    SELECT bs.id_base_site, tmp.:sitesColumnHabitat::integer
    FROM gn_monitoring.t_base_sites AS bs
        JOIN :moduleSchema.:sitesTableTmp AS tmp
            ON (tmp.:sitesColumnCode::character varying = bs.base_site_code)
ON CONFLICT ON CONSTRAINT pk_id_t_infos_site DO NOTHING ;

-- ----------------------------------------------------------------------------
-- REF_GEO
-- NOTE: Integrate sites geom in ref_geo schema only if the site is a mesh.

-- Insert into 'l_areas'
INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source, comment)
    SELECT
        ref_geo.get_id_area_type(s.:sitesColumnType),
        :sitesColumnCode,
        :sitesColumnCode,
        :sitesColumnGeom,
        ST_Centroid(:sitesColumnGeom),
        :'sitesMeshesSource',
        CONCAT('SHT import date: ', :'importDate')
    FROM :moduleSchema.:sitesTableTmp AS s
    WHERE s.:sitesColumnType != ''
        AND s.:sitesColumnType IS NOT NULL
        AND NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS a
            WHERE a.area_code = s.:sitesColumnCode
        ) ;


-- Insert into 'li_grids'
INSERT INTO ref_geo.li_grids
    SELECT
        a.area_code,
        a.id_area,
        ST_XMin(ST_Extent(a.geom)),
        ST_XMax(ST_Extent(a.geom)),
        ST_YMin(ST_Extent(a.geom)),
        ST_YMax(ST_Extent(a.geom))
    FROM ref_geo.l_areas AS a
        JOIN :moduleSchema.:sitesTableTmp AS m
            ON (a.area_code = m.:sitesColumnCode)
    WHERE m.:sitesColumnType != ''
        AND m.:sitesColumnType IS NOT NULL
        AND NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.li_grids AS g
            WHERE g.id_grid = a.area_code
        )
    GROUP BY area_code, id_area ;

-- ----------------------------------------------------------------------------
COMMIT;

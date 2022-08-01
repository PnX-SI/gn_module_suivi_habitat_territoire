-- Script to remove SHT schema and all data linked to SHT insert in GeoNature DB
-- TODO : remove users in t_roles and organisms in bib_organismes ?
BEGIN;

-- -----------------------------------------------------------------------------
-- REF GEO

-- Delete grids
DELETE FROM ref_geo.li_grids
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
            ref_geo.get_id_area_type('M50m'),
            ref_geo.get_id_area_type('M100m')
        )
        AND id_area NOT IN (
            SELECT DISTINCT id_area FROM gn_monitoring.cor_site_area
        )
);

-- Disable dependencies of "ref_geo.l_areas" to speed the deleting
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities DISABLE TRIGGER tri_meta_dates_change_li_municipalities;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT fk_cor_area_synthese_id_area;
ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT fk_cor_area_taxon_id_area;
ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT fk_cor_sensitivity_area_id_area_fkey;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT fk_cor_site_area_id_area;


-- Delete areas
DELETE FROM ref_geo.l_areas
WHERE id_type IN (
        ref_geo.get_id_area_type('M50m'),
        ref_geo.get_id_area_type('M100m')
    )
    AND id_area NOT IN (
        SELECT DISTINCT id_area FROM gn_monitoring.cor_site_area
    );


-- Enable constraints and triggers linked to "ref_geo.l_areas"
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


-- Delete areas types
DELETE FROM ref_geo.bib_areas_types AS bat
WHERE type_code = 'M50m'
AND NOT EXISTS (
    SELECT 'X'
    FROM ref_geo.l_areas AS a
    WHERE a.id_type = bat.id_type
) ;

DELETE FROM ref_geo.bib_areas_types AS bat
WHERE type_code = 'M100m'
AND NOT EXISTS (
    SELECT 'X'
    FROM ref_geo.l_areas AS a
    WHERE a.id_type = bat.id_type
) ;

-- -----------------------------------------------------------------------------
-- REF_TAXONOMY

-- Delete names list : taxonomie.bib_listes, taxonomie.cor_nom_liste, taxonomie.bib_noms
WITH names_deleted AS (
	DELETE FROM taxonomie.cor_nom_liste WHERE id_liste IN (
		SELECT id_liste FROM taxonomie.bib_listes WHERE nom_liste = :'taxonsListName'
	)
	RETURNING id_nom
)
DELETE FROM taxonomie.bib_noms WHERE id_nom IN (
	SELECT id_nom FROM names_deleted
);

DELETE FROM taxonomie.bib_listes WHERE nom_liste = :'taxonsListName';


-- -----------------------------------------------------------------------------
-- REF HABITATS

DELETE FROM ref_habitats.cor_list_habitat
    WHERE id_list IN (
        SELECT id_list FROM ref_habitats.bib_list_habitat WHERE list_name = :'habitatsListName'
    ) ;

DELETE FROM ref_habitats.bib_list_habitat
    WHERE list_name = :'habitatsListName';

-- -----------------------------------------------------------------------------
-- REF NOMENCLATURES

-- Delete nomenclature: ref_nomenclatures.t_nomenclatures,  ref_nomenclatures.bib_nomenclatures_types
-- TODO: vérifier que les perturbations ne sont pas utilisées par un autre module avant de les supprimer !
DELETE FROM ref_nomenclatures.t_nomenclatures
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'perturbationsCode');

DELETE FROM ref_nomenclatures.bib_nomenclatures_types
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(:'perturbationsCode');


-- -----------------------------------------------------------------------------
-- GN_COMMONS

-- Unlink module from dataset
DELETE FROM gn_commons.cor_module_dataset
    WHERE id_module = (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code ILIKE :'moduleCode'
    ) ;

-- Uninstall module (unlink this module of GeoNature)
DELETE FROM gn_commons.t_modules
    WHERE module_code ILIKE :'moduleCode' ;


-- -----------------------------------------------------------------------------
-- GN_MONITORING

-- Remove link between sites and this module
DELETE FROM gn_monitoring.cor_site_module
    WHERE id_module = (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code ILIKE :'moduleCode'
    ) ;

-- Remove links between sites and areas
DELETE FROM gn_monitoring.cor_site_area WHERE id_base_site IN (
        SELECT id_base_site FROM :moduleSchema.t_infos_site
    ) ;

-- Remove base sites data
DELETE FROM gn_monitoring.t_base_sites
    WHERE id_base_site IN (
        SELECT id_base_site FROM :moduleSchema.t_infos_site
    ) ;

-- -----------------------------------------------------------------------------
COMMIT;

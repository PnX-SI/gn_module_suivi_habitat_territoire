-- Script to remove SHT schema and all data linked to SHT insert in GeoNature DB
-- TODO : remove users in t_roles and organisms in bib_organismes ?

-- -----------------------------------------------------------------------------
-- REF_TAXONOMY

-- Delete names list : taxonomie.bib_listes, taxonomie.cor_nom_liste, taxonomie.bib_noms
WITH names_deleted AS (
	DELETE FROM taxonomie.cor_nom_liste WHERE id_liste IN (
		SELECT id_liste FROM taxonomie.bib_listes WHERE nom_liste = 'Suivi Habitat Territoire'
	)
	RETURNING id_nom
)
DELETE FROM taxonomie.bib_noms WHERE id_nom IN (
	SELECT id_nom FROM names_deleted
);

DELETE FROM taxonomie.bib_listes WHERE nom_liste = 'Suivi Habitat Territoire';


-- -----------------------------------------------------------------------------
-- REF HABITATS

DELETE FROM ref_habitats.cor_list_habitat
    WHERE id_list IN (
        SELECT id_list FROM ref_habitats.bib_list_habitat WHERE list_name = 'Suivi Habitat Territoire'
    ) ;

DELETE FROM ref_habitats.bib_list_habitat
    WHERE list_name = 'Suivi Habitat Territoire';

-- -----------------------------------------------------------------------------
-- GN_MONITORING

-- Remove link between sites and this module
DELETE FROM gn_monitoring.cor_site_module
    WHERE id_module = (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code ILIKE 'sht'
    ) ;

-- -----------------------------------------------------------------------------
-- GN_COMMONS

-- Unlink module from dataset
DELETE FROM gn_commons.cor_module_dataset
    WHERE id_module = (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code ILIKE 'sht'
    ) ;

-- Uninstall module (unlink this module of GeoNature)
DELETE FROM gn_commons.t_modules
    WHERE module_code ILIKE 'sht' ;


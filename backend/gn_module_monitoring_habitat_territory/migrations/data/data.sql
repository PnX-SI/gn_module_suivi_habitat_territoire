-- Script to insert references
-- -----------------------------------------------------------------------------
-- TAXONOMY

-- Create monitored taxons list by SHT protocol
INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, regne, group2_inpn, code_liste)
  SELECT
      (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes),
      'Suivi Habitat Territoire',
      'Taxons suivis dans le protocole Suivi Habitat Territoire',
      'Plantae',
      'Angiospermes',
      (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes)
;


-- -----------------------------------------------------------------------------
-- REF HABITATS

-- Create monitored habitats list by SHT protocol
INSERT INTO ref_habitats.bib_list_habitat (list_name)
  SELECT 'Suivi Habitat Territoire'
;

-- -----------------------------------------------------------------------------
-- COMMONS

-- Update SHT module
UPDATE gn_commons.t_modules
SET
    module_label = 'S. Habitat Territoire',
    module_picto = 'fa-map',
    module_desc = 'Module de Suivi des Habitats d''un Territoire'
WHERE module_code ILIKE 'SHT' ;

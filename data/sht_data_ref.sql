-- Script to insert references
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'REF GEO'

\echo 'Insert 100x100 meters meshes new area type in `ref_geo.bib_areas_types`'
WITH test_exists AS (
    SELECT id_type
    FROM ref_geo.bib_areas_types
    WHERE type_code = 'M100m'
)
INSERT INTO ref_geo.bib_areas_types (type_code, type_name, type_desc)
  SELECT 'M100m', 'Mailles100*100m', 'Maille INPN redécoupé en 100m'
WHERE NOT EXISTS (
  SELECT id_type FROM test_exists
)
RETURNING id_type ;


\echo 'Insert 50x50 meters meshes new area type in `ref_geo.bib_areas_types`'
WITH test_exists AS (
    SELECT id_type
    FROM ref_geo.bib_areas_types
    WHERE type_code = 'M50m'
)
INSERT INTO ref_geo.bib_areas_types (type_code, type_name, type_desc)
  SELECT 'M50m', 'Mailles50*50m', 'Maille INPN redécoupé en 50m'
WHERE NOT EXISTS (
  SELECT id_type FROM test_exists
)
RETURNING id_type ;


\echo '--------------------------------------------------------------------------------'
\echo 'TAXONOMY'

\echo 'Create monitored taxons list by SHT protocol'
WITH test_exists AS (
    SELECT id_liste
    FROM taxonomie.bib_listes
    WHERE nom_liste = :'taxonsListName'
)
INSERT INTO taxonomie.bib_listes (id_liste, nom_liste, desc_liste, regne, group2_inpn)
  SELECT
      (SELECT MAX(id_liste) + 1 FROM taxonomie.bib_listes),
      :'taxonsListName',
      'Taxons suivis dans le protocole Suivi Habitat Territoire',
      'Plantae',
      'Angiospermes'
WHERE NOT EXISTS (
  SELECT id_liste FROM test_exists
)
RETURNING id_liste ;


\echo '--------------------------------------------------------------------------------'
\echo 'REF HABITATS'

\echo 'Create monitored habitats list by SHT protocol'
WITH test_exists AS (
    SELECT id_list
    FROM ref_habitats.bib_list_habitat
    WHERE list_name = :'habitatsListName'
)
INSERT INTO ref_habitats.bib_list_habitat (list_name)
  SELECT :'habitatsListName'
WHERE NOT EXISTS (
  SELECT id_list FROM test_exists
)
RETURNING id_list ;


\echo '--------------------------------------------------------------------------------'
\echo 'REF NOMENCLATURES'

\echo 'Add nomenclature value for SHT site type nomenclature (="TYPE_SITE")'
WITH test_exists AS (
    SELECT id_nomenclature
    FROM ref_nomenclatures.t_nomenclatures
    WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE')
        AND cd_nomenclature = :'sitesTypeCode'
)
INSERT INTO ref_nomenclatures.t_nomenclatures
    (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr, source)
SELECT
    ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE'),
    :'sitesTypeCode',
    'Zone d''habitat',
    'Zone d''habitat - suivi habitat territoire',
    'Zone d''habitat',
    'Zone d''habitat - issu du module Suivi Habitat Territoire (SHT)',
    :'sitesTypeSrc'
WHERE NOT EXISTS (SELECT id_nomenclature FROM test_exists)
RETURNING id_nomenclature ;


\echo 'Create the "Perturbation" nomenclature type'
WITH test_exists AS (
    SELECT id_type
    FROM ref_nomenclatures.bib_nomenclatures_types
    WHERE mnemonique = :'perturbationsCode'
)
INSERT INTO ref_nomenclatures.bib_nomenclatures_types
    (mnemonique, label_default, definition_default, label_fr, definition_fr, source)
SELECT
    :'perturbationsCode',
    'Type de perturbations',
    'Nomenclature des types de perturbations.',
    'Type de perturbations',
    'Nomenclatures des types de perturbations.',
    :'perturbationsSrc'
WHERE NOT EXISTS (SELECT id_type FROM test_exists)
RETURNING id_type ;


\echo '--------------------------------------------------------------------------------'
\echo 'COMMONS'

\echo 'Update SHT module'
UPDATE gn_commons.t_modules
SET
    module_label = 'S. Habitat Territoire',
    module_picto = 'fa-map',
    module_desc = 'Module de Suivi des Habitats d''un Territoire',
WHERE module_code = 'SHT' ;

-- -------------------------------------------------------------------------------
COMMIT;

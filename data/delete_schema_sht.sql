--------------------------
-- Supprimer un schéma -- 
--------------------------

DROP SCHEMA pr_monitoring_habitat_territory CASCADE;
--=> ne fonctionne pas obligé de supprimer les tables une par une, redémarrage de postgres pour cor_visit_perturbation
--puis drop SCHEMA...


---------------------------------
-- Supprimer données associées -- 
---------------------------------

--suppression des SITES
DELETE from gn_monitoring.t_base_sites where base_site_name like 'HAB-%';
--=> TODO faire un select avec id_nomenclature de la table..


--suppression des données géométriques
--li_grids
DELETE from ref_geo.li_grids where id_area IN (SELECT id_area FROM ref_geo.l_areas WHERE id_type=ref_geo.get_id_area_type('M100m'));

--l_areas
DELETE from ref_geo.l_areas WHERE id_type=ref_geo.get_id_area_type('M100m');

--bib_areas_types
DELETE from ref_geo.bib_areas_types where type_name='Mailles100*100m';


--suppression nomenclature perturbation
DELETE FROM ref_nomenclatures.t_nomenclatures WHERE cd_nomenclature='HAB';


-- suppression des espèces
DELETE FROM taxonomie.bib_listes WHERE nom_liste='Suivi Habitat Territoire';


--suppression habitats
-- Insérer habitat
DELETE FROM ref_habitat.cor_list_habitat WHERE id_list IN (SELECT id_list FROM ref_habitat.bib_list_habitat WHERE list_name='Suivi Habitat Territoire');

-- insérer une liste d'habitat
DELETE FROM ref_habitat.bib_list_habitat WHERE list_name='Suivi Habitat Territoire';


-- parametrer ref_geo.bib_areas_types -- 
-- créer le type de mailles 100*100 
-- problème : ne supporte pas dimension Z => suppression info dans QGIS
INSERT INTO ref_geo.bib_areas_types (type_name, type_code, type_desc)
VALUES ('Mailles100*100m', 'M100m', 'Maille INPN redécoupé en 100m');

--insérer les mailles dans l_areas grâce au fichier maille_tmp
INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
SELECT ref_geo.get_id_area_type('M100m'), name, name, geom, ST_CENTROID(geom), 'INPN'
FROM pr_monitoring_habitat_territory.maille_tmp; 

-- insérer les mailles dans li_grids
INSERT INTO ref_geo.li_grids
SELECT area_code, id_area, ST_XMin(ST_Extent(geom)), ST_XMax(ST_Extent(geom)), ST_YMin(ST_Extent(geom)),ST_YMax(ST_Extent(geom))
FROM ref_geo.l_areas
WHERE id_type=ref_geo.get_id_area_type('M100m')
GROUP by area_code, id_area;


-- créer nomenclature  HAB --  
INSERT INTO ref_nomenclatures.t_nomenclatures (id_type, cd_nomenclature, mnemonique, label_default, label_fr, definition_fr, source )
VALUES (ref_nomenclatures.get_id_nomenclature_type('TYPE_SITE'), 'HAB', 'Zone de habitat', 'Zone de habitat - suivi habitat territoire', 'Zone d''habitat',  'Zone d''habitat issu du module suivi habitat territoire', 'CBNA');




-- insérer les données dans t_base_sites grâce à celles dans la table maille_tmp
-- ATTENTION: il faut que le maille_tmp.shp soit en 2154, sinon ça donne des erreurs pour afficher les sites.  
INSERT INTO gn_monitoring.t_base_sites
(id_nomenclature_type_site, base_site_name, base_site_description,  base_site_code, first_use_date, geom )
SELECT ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'HAB'), 'HAB-', '', name, now(), ST_TRANSFORM(ST_SetSRID(geom, MY_SRID_LOCAL), MY_SRID_WORLD)
FROM pr_monitoring_habitat_territory.maille_tmp;

--- update le nom du site pour y ajouter l'identifiant du site
UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, id_base_site); 

-- extension de la table t_base_sites : mettre les données dans t_infos_site
-- TEST --
/*INSERT INTO pr_monitoring_habitat_territory.t_infos_site (id_base_site, cd_hab)
VALUES (17,16265);*/

-- TEST --
/*
INSERT INTO pr_monitoring_habitat_territory.t_infos_site (id_base_site, cd_hab)
SELECT id_base_site, zh.cd_hab
FROM gn_monitoring.t_base_sites bs
JOIN pr_monitoring_habitat_territory.maille_tmp zh ON zh.name::character varying = bs.base_site_code;
*/

-- insérer les données cor_habitat_taxon : liaison un taxon et son habitat
/*INSERT INTO pr_monitoring_habitat_territory.cor_habitat_taxon (id_habitat, cd_nom)
VALUES (16265, 104123);*/

-- TODO insert visit
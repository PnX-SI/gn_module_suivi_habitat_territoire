-- Supprimer un schéma -- 
DROP SCHEMA pr_monitoring_habitat_territory CASCADE;

-- Supprimer données associées -- 
--delete from gn_monitoring.t_base_sites WHERE base_site_name LIKE 'HAB-%';
--DELETE from ref_geo.li_grids where id_area IN (SELECT id_area FROM ref_geo.l_areas WHERE id_type=ref_geo.get_id_area_type('M100m'));


Intégrer les mailles
--------------------

* Vérifier que vous n'intégrez pas des mailles déjà présentes. Les mailles ne doivent pas contenir la dimension Z, la projection doit être en Lambert93.
* Copier les mailles dans le dossier /tmp du serveur :

.. code:: bash

    # placez-vous dans le dossier du module suivi_habitat_territoire
    cp data/sht_data.sql /tmp/sht_data.sql

* Créer une table temporaire à partir des fichiers mailles :

.. code:: bash

    sudo -n -u postgres -s shp2pgsql -W "UTF-8" -s 2154 -D -I /tmp/maille100z93.shp pr_monitoring_habitat_territory.maille_tmp | psql -h $db_host -U $user_pg -d $db_name &>> var/log/install_maille.log


* Parametrer ``ref_geo.bib_areas_types`` :

.. code:: sql

    -- créer le type de mailles 100*100
    INSERT INTO ref_geo.bib_areas_types (type_name, type_code, type_desc)
        VALUES ('Mailles100*100m', 'M100m', 'Maille INPN redécoupé en 100m');


* Insérer les mailles dans ``ref_geo.l_areas`` grâce au fichier maille_tmp :

.. code:: sql

    INSERT INTO ref_geo.l_areas (id_type, area_name, area_code, geom, centroid, source)
    SELECT ref_geo.get_id_area_type('M100m'), name, name, geom, ST_CENTROID(geom), 'INPN'
    FROM pr_monitoring_habitat_territory.maille_tmp;


* Insérer les mailles dans ``ref_geo.li_grids`` :

.. code:: sql

    INSERT INTO ref_geo.li_grids
    SELECT area_code, id_area, ST_XMin(ST_Extent(geom)), ST_XMax(ST_Extent(geom)), ST_YMin(ST_Extent(geom)),ST_YMax(ST_Extent(geom))
    FROM ref_geo.l_areas
    WHERE id_type=ref_geo.get_id_area_type('M100m')
    GROUP by area_code, id_area;


Intégrer les habitats
---------------------

* Créer une liste d'habitat :

.. code:: sql

    INSERT INTO ref_habitat.bib_list_habitat (list_name)
        VALUES ('Suivi Habitat Territoire');

* Ajouter les habitats dans la liste :

.. code:: sql

    INSERT INTO ref_habitat.cor_list_habitat (id_list, cd_hab)
        VALUES (
        (SELECT id_list FROM ref_habitat.bib_list_habitat WHERE list_name='Suivi Habitat Territoire'), 16265); -- CARICION INCURVAE


Intégrer les espèces
---------------------

* Insérer les données ``pr_monitoring_habitat_territory.cor_habitat_taxon`` : liaison un taxon et son habitat :

.. code:: sql

    INSERT INTO pr_monitoring_habitat_territory.cor_habitat_taxon (id_habitat, cd_nom)
    VALUES
    (16265, 104123),
    (16265, 88386),
    (16265, 88662),
    (16265, 88675),
    (16265, 88380),
    (16265, 88360),
    (16265, 127195),
    (16265, 126806);


Intégrer les sites
-------------------

* Remplissez les tables de la BDD à partir de cette table temporaire :

.. code:: sql

    -- insérer les données dans ``gn_monitoring.t_base_sites`` grâce à celles dans la table ``pr_monitoring_habitat_territory.maille_tmp``
    INSERT INTO gn_monitoring.t_base_sites
    (id_nomenclature_type_site, base_site_name, base_site_description,  base_site_code, first_use_date, geom )
        SELECT ref_nomenclatures.get_id_nomenclature('TYPE_SITE', 'HAB'), 'HABSHT-', '', name, now(), ST_TRANSFORM(ST_SetSRID(geom, MY_SRID_LOCAL), MY_SRID_WORLD)
            FROM pr_monitoring_habitat_territory.maille_tmp;

    --- mise à jour du nom du site pour y ajouter l'identifiant du site
    UPDATE gn_monitoring.t_base_sites SET base_site_name=CONCAT (base_site_name, id_base_site)
        WHERE base_site_code IN (SELECT name FROM pr_monitoring_habitat_territory.maille_tmp);

    -- Ajouter les données dans pr_monitoring_habitat_territory.t_infos_site
    INSERT INTO pr_monitoring_habitat_territory.t_infos_site (id_base_site, cd_hab)
        SELECT id_base_site, 16265
            FROM gn_monitoring.t_base_sites bs
            JOIN pr_monitoring_habitat_territory.maille_tmp mt ON mt.name::character varying = bs.base_site_code;


La table ``gn_monitoring.cor_site_area`` est remplie automatiquement par trigger pour indiquer les communes et mailles 25m de chaque ZP.

* Insérer les sites suivis de ce module dans ``cor_site_application`` :

.. code:: sql

    -- Insérer dans cor_site_module les sites suivis de ce module
    INSERT INTO gn_monitoring.cor_site_module
        WITH id_module AS(
            SELECT id_module FROM gn_commons.t_modules
            WHERE module_code ILIKE 'SUIVI_HAB_TER'
        )
        SELECT ti.id_base_site, id_module.id_module
            FROM pr_monitoring_habitat_territory.t_infos_site ti, id_module;


Intégrer les perturbations
--------------------------
* ATTENTION AUX DOUBLONS : Vérifier que les perturbations de type ``TYPE_PERTURBATION`` ne sont pas déjà intégrer

.. code:: bash

    -- placez-vous dans le dossier du module suivi_habitat_territoire
    cp data/sht_perturbations.sql /tmp/sht_perturbations.sql
    psql -h $db_host -U $user_pg -d $db_name -f /tmp/sht_perturbations.sql &>> var/log/install_sht_perturbations.log


Intégrer les visites
--------------------

Le template du CSV pour l'insertion des visites est celui généré par l'export des visites.

* Importer le CSV dans une table temporaire de la BDD avec QGIS (``pr_monitoring_habitat_territory.obs_maille_tmp`` dans cet exemple)
* Identifier les organismes présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT unnest(string_to_array(organisme, ',')) AS organisme FROM pr_monitoring_habitat_territory.obs_maille_tmp ORDER BY organisme``
* Identifier les observateurs présents dans les observations et intégrez ceux manquants dans UsersHub : ``SELECT DISTINCT unnest(string_to_array(observateu, ',')) AS observateurs FROM pr_monitoring_habitat_territory.obs_maille_tmp ORDER BY observateurs``
* Remplissez la table des visites :

.. code:: sql

    INSERT INTO gn_monitoring.t_base_visits (id_base_site, visit_date_min)
    SELECT DISTINCT s.id_base_site, "date visit"::date AS date_debut
        FROM pr_monitoring_habitat_territory.obs_maille_tmp o
        JOIN gn_monitoring.t_base_sites s ON s.base_site_name = o."nom du sit";

* Remplissez la table des observateurs :

.. code:: sql

    INSERT INTO gn_monitoring.cor_visit_observer
      (id_base_visit, id_role)
    WITH myuser AS(SELECT lower(unnest(string_to_array(observateu, ','))) AS obs, identifian, "nom du sit" AS name  FROM pr_monitoring_habitat_territory.obs_maille_tmp),
        roles AS(SELECT lower(nom_role ||' '|| prenom_role) AS nom, id_role FROM utilisateurs.t_roles)
    SELECT DISTINCT v.id_base_visit,r.id_role
    FROM myuser m
    JOIN gn_monitoring.t_base_sites s ON s.base_site_name = m.name
    JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
    JOIN roles r ON m.obs=r.nom
    ON CONFLICT DO NOTHING;

* Remplissez la table des observations :

.. code:: sql

    -- taxons : pr_monitoring_habitat_territory.cor_visit_taxons
    INSERT INTO pr_monitoring_habitat_territory.cor_visit_taxons (id_base_visit, cd_nom)
    WITH mytaxon AS(SELECT unnest(string_to_array(covtaxons, ',')) AS cdnom,
        identifian, "nom du sit" AS name  FROM pr_monitoring_habitat_territory.obs_maille_tmp)
    SELECT DISTINCT v.id_base_visit, m.cdnom::int
    FROM mytaxon m
    JOIN gn_monitoring.t_base_sites s ON s.base_site_name = m.name
    JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
    ON CONFLICT DO NOTHING;

    -- perturbation : pr_monitoring_habitat_territory.cor_visit_perturbation
    INSERT INTO pr_monitoring_habitat_territory.cor_visit_perturbation (id_base_visit, id_nomenclature_perturbation, create_date)
    WITH mypertub AS(SELECT unnest(string_to_array(perturbati, ',')) AS label_perturbation,
        identifian, "nom du sit" AS name, "date visit"::date AS date_visit  FROM pr_monitoring_habitat_territory.obs_maille_tmp)
    SELECT DISTINCT
        v.id_base_visit,
        nm.id_nomenclature,
        m.date_visit
    FROM mypertub m
    JOIN gn_monitoring.t_base_sites s ON s.base_site_name = m.name
    JOIN gn_monitoring.t_base_visits v ON v.id_base_site = s.id_base_site
    JOIN ref_nomenclatures.t_nomenclatures nm
        ON nm.id_nomenclature = (SELECT n.id_nomenclature
                                    FROM ref_nomenclatures.t_nomenclatures n
                                    WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type('TYPE_PERTURBATION') AND 'Arrachage' = n.mnemonique LIMIT 1);

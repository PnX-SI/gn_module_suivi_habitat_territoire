SET search_path = ref_habitat, pg_catalog, public;

TRUNCATE TABLE typoref CASCADE;
COPY ref_habitat.typoref ( cd_typo,cd_table,lb_nom_typo,nom_jeu_donnees,date_creation,date_mise_jour_table,
    date_mise_jour_metadonnees,
    auteur_typo,
    auteur_table,
    territoire,
    organisme,
    langue,
    presentation,
    description,
    origine,
    ref_biblio,
    mots_cles,
    referencement,
    diffusion,
    derniere_modif,
    type_table,
    cd_typo_entre,
    cd_typo_sortie, niveau_inpn )
FROM  '/tmp/habref/TYPOREF_40.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'UTF-8';


TRUNCATE TABLE ref_habitat.habref CASCADE;
COPY ref_habitat.habref (cd_hab,fg_validite,cd_typo,lb_code,lb_hab_fr,lb_hab_fr_complet,
    lb_hab_en,lb_auteur,niveau,lb_niveau,cd_hab_sup,path_cd_hab,france,lb_description)
FROM  '/tmp/habref/HABREF_40.csv'
WITH  CSV HEADER 
DELIMITER ';'  encoding 'UTF-8';
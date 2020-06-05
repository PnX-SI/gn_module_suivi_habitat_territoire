# Importation de données pour le module Suivi Habitat Territoire

Plusieurs scripts sont disponibles pour importer les données manipulées dans le module SHT. Les données sources à importer doivent être fourni au format CSV (encodage UTF-8) ou Shape en fonction du type de données suivantes :
 - nomenclatures (`import_nomenclatures.sh`) : CSV
 - taxons (`import_taxons.sh`) : CSV
 - habitats (`import_habitats.sh`) : CSV
 - sites (`import_sites.sh`) : Shape
 - visites et observations (`import_visits.sh`) : CSV

Chacun de ces scripts est disponibles dans le dossier `bin/`.

Avant de lancer les scripts, il est nécessaires de correctement les paramètrer à l'aide d'un fichier `config/imports_settings.ini`. Vous pouvez copier/coller le fichier `config/imports_settings.sample.ini` en le renomant `imports_settings.ini`.

Dans le fichier `imports_settings.ini`, une section de paramètres concerne chacun d'entre eux. Ces paramètres permettent entre autre d'indiquer :
 - le chemin et le nom vers le fichier source (CSV ou Shape)
 - le chemin et le nom du fichier de log où les informations affichées durant son execution seront enregistrées
 - le nom des tables temporaires dans lesquelles les données sources sont stockées avant import dans les tables de GeoNature. Elles sont toutes crées dans le schema du module.
 - pour les fichiers source de type Shape (sites), les noms des champs des attributs des objets géographiques
 - pour les fichiers source de type CSV (visites), les noms des colonnes

 Enfin, pour chaque import le paramètre *import_date* doit être correctement renseigné avec une date au format `yyyy-mm-dd` distincte. Cette date permet d'associer dans la base de données, les sites et visites mais aussi les utilisateurs (=`role`) et organismes à l'import courant.  
 Laisser en commentaire dans le fichier `imports_settings.ini` les dates utilisées pour chaque import.  
 Vous n'ête en aucun cas obligé d'utiliser la date courante, vous être libre de choisir celle qui vous convient le mieux.


## Format des données
Voici le détail des champs des fichiers CSV ou Shape attendus par défaut :


### Nomenclatures (CSV)

Description des colonnes attendues dans le fichier CSV contenant la liste des nomenclatures utilisée (les types de perturbation des sites) :

 - **type_nomenclature_code** : code du type de nomeclature à laquelle correspond cette valeur de nomenclature. Ex. : *TYPE_PERTURBATION*.
 - **cd_nomenclature** : code de la nomenclature. Ex. : *GeF*.
 - **mnemonique** : libellé court de la nomenclature. Ex. *Gestion par le feu*.
 - **label_default** : libellé par défaut de la nomenclature. Ex. *Gestion par le feu*.
 - **definition_default** : définition courte par défaut de la nomenclature. Ex. *Type de perturbation : gestion par le feu*.
 - **label_fr** : libellé en français de la nomenclature. Ex. *Gestion par le feu*.
 - **definition_fr** : définition courte en français de la nomenclature. Ex. *Type de perturbation : gestion par le feu*.
 - **cd_nomenclature_broader** : code de la nomenclature parente si elle existe. Utiliser 0 si la nomenclature n'pas de parente.
 - **hierarchy**: hiérarchie de code numérique sur 3 chiffres séparés par des points. Doit débuter par un point. Ex. *.001* pour une valeur n'ayant pas de parent ou *.001.002* pour la seconde valeur *.002* de la valeur parente *.001*.


### Taxons (CSV)

Description des colonnes attendues dans le fichier CSV contenant la liste des taxons suivis :

 - **cd_nom** : code TaxRef du nom du taxon lié a un habitat suivi
 - **cd_ref** : code TaxRef du nom de référence du taxon lié a un habitat suivi
 - **name** : nom français à utiliser lors de l'affichage des listes d'autocomplétion.
 - **comment** : commentaire associé au nom


### Habitats (CSV)
Description des colonnes attendues dans le fichier CSV contenant la liste des habitats suivis :

 - **cd_hab** : code HabRef de l'habitat.
 - **cd_nom** : code TaxRef du nom du taxon lié à l'habitat.
 - **comment** : commentaire/note sur l'habitat et le taxon.

Paramètres présent dans le fichier de configuration:
 - **habitats_table_tmp** : nom de la table temporaire contenant les habitats créée dans Postgresql.


### Sites (Shape)

Description des paramètres de configuration permettant d'indiquer les noms des champs utilisés dans les attributs des objets géographiques du fichier Shape pour les sites :

 - **sites_column_type** : nom du champ contenant le type mailles correspondant au site.
 - **sites_column_code** : nom du champ contenant le code du site.
 - **sites_column_habitat** : nom du champ contenant le code de l'habitat du site (='cd_hab').
 - **sites_column_desc** : nom du champ contenant la description du site.

Autres paramètres :
 - **sites_column_geom** : nom du champ contenant la géométrie du site dans la table temporaire créé dans Postgresql. Ce champ n'a pas à apparaitre dans les attributs des objets géographique. Par défaut, l'utilitaire employé par le script (*shp2pgsql*) créé une colonne ayant pour libellé *geom* en se basant sur les infos géographiques du fichier Shape.
 - **sites_table_tmp** : nom de la table temporaire contenant les sites créée dans Postgresql.
 - **sites_meshes_source** : lorsque un site correspond à une maille, la valeur de ce paramètre est utilisée pour renseigner la source de la maille.


### Visites et observations (CSV)
Description des colonnes attendues dans le fichier CSV contenant la liste des visites et observations. Les nom des colonnes peuvent modifié à l'aide des paramètres du fichier de configuration indiqués ici entre parenthèses :

 - **idzp** (*visits_column_id*) : identifiant ou code alphanumérique du site où a eu lieu la visite. Le même site référencé dans 2 imports distincts doit avoir le même identifiant dans ce champ. Deux sites différents ne doivent en aucun cas posséder le même identifiant.
 - **cd25m** (*visits_column_meshe*) : code de la maille où a eu lieu la visite.
 - **observateu** (*visits_column_observer*) : liste des observateurs au format "NOM Prénom" séparés par des pipes "|". L'ordre doit correspondre à l'ordre des organismes du champ *organimes*.
 - **organismes** (*visits_column_organism*) : liste des organimes séparés par des pipes "|". L'ordre doit correspondre à l'ordre des observateurs du champ *observateu*.
 - **date_deb** (*visits_column_date_start*) : date de début de la visite.
 - **date_fin** (*visits_column_date_end*) : date de fin de la visite. Elle sera identique à *date_deb* si la visite a eu lieu sur un seul jour.
 - **presence** (*visits_column_status*) : permet d'indiquer la 'presence' (pr), l'absence (ab) ou l nom observation (na) du taxon sur la maille.

 Autres paramètres :
 - **visits_table_tmp_visits** : nom de la table temporaire contenant les visites par maille.
 - **visits_table_tmp_has_observers** : nom de la table temporaire contenant les liens entre visites et observateurs.
 - **visits_table_tmp_observers** : nom de la table temporaire contenant les prénoms nom des observateurs et leur organisme.


## Options des scripts d'import

Il possèdent tous les options suivantes :
 - `-h` (`--help`) : pour afficher l'aide du script.
 - `-v` (`--verbosity`) : le script devient verbeux est affiche plus de messages concernant le travail qu'il accomplit.
 - `-x` (`--debug`) : le mode débogage de Bash est activé.
 - `-c` (`--config`) : permet d'indiquer le chemin vers un fichier de configuration spécifique. Par défaut, c'est le fichier `config/settings.ini` qui est utilisé.
 - `-d` (`--delete`) : chacun des imports peut être annulé avec cette option. Attention, il faut s'assurer que le script est correctement configuré avec les paramètres correspondant à l'import que vous souhaitez annuler.


## Procédure

Afin que les triggers présents sur les tables soient déclenchés dans le bon ordre et que les scripts trouvent bien les données de référence dont ils ont besoin, il est obligatoire de lancer les scripts dans cet ordre :
 1. nomenclatures : `import_nomenclatures.sh`
 2. taxons : `import_taxons.sh`
 3. habitats : `import_habitats.sh`
 4. sites : `import_sites.sh`
 5. visites et observations : `import_visits.sh`

Attention, la désinstallation des données importées se fait dans le sens inverse. Il faut commencer par les visites puis passer aux sites...  
Concernant la désinstallation, il s'agit d'une manipulation délicate à utiliser principalement sur une base de données de test ou lors du développement du module. En production, nous vous conseillons fortement d'éviter son utilisation. Si vous y êtes contraint, veuillez sauvegarder votre base de données auparavant.

Pour lancer un script, ouvrir un terminal et se placer dans le dossier `bin/` du module SFT.
Ex. pour lancer le script des visites :
 - en importation : `./import_visits.sh`
 - en suppression des imports précédents : `./import_visits.sh -d`

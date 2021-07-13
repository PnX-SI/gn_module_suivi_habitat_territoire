# Module - Suivi Habitat Territoire

Module GeoNature de Suivi des Habitats sur un Territoire (SHT) du réseau Flore Sentinelle, piloté par le CBNA.

![SHT module](docs/img/main_screen.png)


## Installation

* Installez GeoNature (https://github.com/PnX-SI/GeoNature) en version 2.3.0 ou supérieure.
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/archive/X.Y.Z.zip``) dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes suivantes (le nom du module abrégé en "sht" est utilisé comme code) :

```
    source venv/bin/activate
    geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>
    # Exemple geonature install_gn_module /home/`whoami`/gn_module_suivi_habitat_territoire-X.Y.Z /sht)
```

* L'installation du module doit créer le fichier ``config/settings.ini`` et y stocker le chemin vers le fichier de configuration de GeoNature. Vous pouvez maintenant :
    * le compléter à partir du fichier d'exemple ``config/settings.sample.ini``
    * (optionel) surcoucher éventuellement un des paramètres présent dans le fichier ``config/settings.default.ini``
* Réaliser les imports nécessaires au fonctionnement du module à l'aide des scripts disponibles :
  * placer les fichiers CSV à importer dans le dossier `data/imports/`
  * configurer les paramètres d'import : `cp config/imports_settings.sample.ini config/imports_settings.ini ; vi config/imports_settings.ini`
  * se placer dans le dossier des scripts : `cd bin/`
  * importer :
    * les valeurs pour la nomenclature "Perturbation" : `./import_nomenclatures.sh -v`
    * les taxons qui correspondent aux habitats suivis : `./import_taxons.sh -v`
    * les habitats et les taxons associées : `./import_habitats.sh -v`
    * les sites : `./import_sites.sh -v`
    * les visites (optionnel) : `./import_visits.sh -v`
    * les observations (optionnel) : `./import_observations.sh -v`
* Vous trouverez plus d'informations sur l'importation de données et ces scripts dans [la documentation qui leur est dédiée](docs/import-data.md).
* Complétez la configuration du module dans le fichier ``config/conf_gn_module.toml`` en surcouchant les valeurs par défaut présentes dans le fichier ``config/conf_gn_module.sample.toml``:
  * Commande pour copier le fichier par défaut : ``cp config/conf_gn_module.sample.toml config/conf_gn_module.toml``
  * Remplacer, si nécessaire, les identifiants des listes en les récupérant dans la base de données pour : `id_type_maille`, `id_type_commune`, `id_menu_list_user`, `id_list_taxon`
  * Ensuite, relancez la mise à jour de la configuration de GeoNature :
    * Se rendre dans le répertoire ``geonature/backend``
    * Activer le venv (si nécessaire) : ``source venv/bin/activate``
    * Lancer la commande de mise à jour de configuration du module (abrégé ici en "sht")  : ``geonature update_module_configuration sht``
* Vous pouvez sortir du venv en lançant la commande ``deactivate``


## Désinstallation

* Utiliser le script `bin/uninstall_db.sh` en vous plaçant dans le dossier bin puis en éxecutant : `./uninstall_db.sh`
* Cette action va supprimer toutes les données et structures en lien avec le module SHT dans la base de données.
* Vous pouvez ensuite supprimer le lien symbolique dans le dossier ``geonature/external_modules/``


## Licence

* [Licence OpenSource GPL v3](./LICENSE.txt)
* Copyleft 2018-2020 - Parc National des Écrins - Conservatoire National Botanique Alpin

[![Logo PNE](http://geonature.fr/img/logo-pne.jpg)](http://www.ecrins-parcnational.fr)

[![Logo CBNA](http://www.cbn-alpin.fr/images/stories/habillage/logo-cbna.jpg)](http://www.cbn-alpin.fr)

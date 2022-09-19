# Installation/Désinstallation du module

## Prérequis

- Avoir [installé GeoNature](https://github.com/PnX-SI/GeoNature) en version v2.9.2 ou plus.

## Installation

**Notes :** l'installation proposée ici est en mode *développement*. Pour la *production*, supprimez les options `--build false` des commandes.

1. Téléchargez le module sur votre serveur [à partir d'une release](https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/releases) :
    ```bash
    wget https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/archive/X.Y.Z.zip
    ```
2. Créez un dossier qui contiendra vos modules :
    ```bash
    mkdir /home/${USER}/modules
    ```
3. Dézippez dans `/home/${USER}/modules` avec :
    ```
    unzip X.Y.Z.zip
    ```
4. Placez-vous dans le dossier de GeoNature et activez le venv :
    ```bash
    source backend/venv/bin/activate
    ```
5. Installez le module avec la commande :
    ```bash
    geonature install-packaged-gn-module --build false /home/${USER}/modules/gn_module_suivi_habitat_territoire SHT
    ```
    - Adaptez le chemin `/home/${USER}/modules/gn_module_suivi_habitat_territoire` à votre installation.
6. Complétez la configuration du module uniquement si nécessaire :
    ```bash
    nano config/conf_gn_module.toml
    ```
    - Vous trouverez les paramètres possibles dans le fichier : `config/conf_gn_module.toml.example`.
    - Les valeurs par défaut dans : `backend/gn_module_monitoring_habitat_territory/conf_schema_toml.py`
7. Mettre à jour le frontend :
    ```bash
    geonature update-configuration --build false && geonature generate-frontend-tsconfig && geonature generate-frontend-tsconfig-app && geonature generate-frontend-modules-route
    ```
8. Vous pouvez sortir du venv en lançant la commande : `deactivate`


## Désinstallation

**⚠️ ATTENTION :** la désinstallation du module implique la suppression de toutes les données associées. Assurez vous d'avoir fait une sauvegarde de votre base de données au préalable.

Suivez la procédure suivante :
1. Rétrograder la base de données pour y enlever les données spécifiques au module :
    ```bash
    geonature db downgrade sht@base
    ```
1. Désinstaller le package du virtual env :
    ```
    pip uninstall gn-module-monitoring-habitat-territory
    ```
    - Possibilité de voir le nom du module avec : `pip list`
1. Supprimer la ligne relative au module dans `gn_commons.t_modules`
1. Supprimer le lien symbolique du module dans les dossiers :
    - `geonature/external_modules`
    - `geonature/frontend/src/external_assets/`
1. Mettre à jour le frontend :
    ```bash
    geonature update-configuration --build false && geonature generate-frontend-tsconfig && geonature generate-frontend-tsconfig-app && geonature generate-frontend-modules-route
    ```

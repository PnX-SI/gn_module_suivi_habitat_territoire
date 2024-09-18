# Changelog

Toutes les modifications notables apportées à ce projet seront documentées dans ce fichier en français.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [Inédit]


## [1.2.0] - 2024-08-20

### 🚀 Ajouté

- Compatibilité avec GeoNature 2.14
- Permissions de module (CRUVED) déclarées dans la branche Alembic.
- Ajout de la date de création par défaut (maintenant) dans `pr_monitoring_habitat_territory.cor_visit_perturbation`
- Utilisation du nouveau format `pyproject.toml` pour l'installation et la définition des dépendances du module à la place du fichier `setup.py`
- Ajout d'un exemple de fichier `tsconfig.json` à utiliser pour les développements du module à l'extérieur du dossier de GeoNature

### 🔄 Modifié

- Mise à jour de `install.md`
- Mise à jour de `requirements.in`
- Les fonctions `check_user_cruved_visit` et `cruved_scope_for_user_in_module` sont remplacées par la classe `VisitAuthMixin`, qui contient des méthodes permettant de récupérer les droits d'utilisateur sur les données (action CRUVED + portée).

### 🐛 Corrigé

- Correction du service Web `GET /sites` qui renvoie désormais les sites sans visites.
- Correction du service Web `PATCH /visits/<int:idv>`. Nous excluons la visite corrigée actuelle de la vérification de l'année des visites.
- Correction du chemin des assets du module utilisé pour l'URL (PnX-SI/GeoNature#2957)
- Réduction de la durée de chargement de la liste des sites sur la page d'accueil.


## [1.1.0] - 2022-10-22

### 🚀 Ajouté

- Ajout de la mémorisation entre deux accès des valeurs des filtres de la vue liste des sites (#28).
- Ajout d'un indicateur de chargement sur les tables de données de la vue liste des visites et de la vue liste des sites (#29).
- Ajout d'un spinner global à la vue liste des visites.
- Ajout de l'affichage de l'UUID du site à la vue liste des visites.
- Ajout de nouvelles colonnes dans l'export des visites (#23) :
- L'identifiant de la visite est exporté dans la colonne "_visit_id_".
- L'UUID des sites est exporté dans la colonne "_base_site_uuid_".
- Ajout du nom de l'organisation entre parenthèses pour chaque observateur sur la vue liste des visites.
- Ajout de l'affichage des taxons non-habitat présents dans la base de données dans
une section spécifique de la fenêtre modale d'édition de visite.
- Ajout de l'affichage du contenu du message d'erreur reçu après soumission
du formulaire de la fenêtre modale d'édition de visite.

### 🔄 Modifié

- Les filtres des communes et organismes utilisent désormais un identifiant au lieu d'un
libellé pour récupérer les visites correspondantes.
- Modification du zoom initial utilisé pour la carte de la vue liste des sites. Zoom vers le bas.
- Modification de l'affichage de la légende de la carte :
- Utilisation du numéro des années au lieu de "_year+1_", "_year+2_"...
- Utilisation de couleurs distinctes au lieu d'une graduation de couleur rouge : bleu, vert, jaune, orange et rouge.
- Les sites avec visite récente utilisent la couleur froide (bleu) et les sites avec visites anciennes utilisent la couleur chaude (rouge).
- Modification de la couleur du marqueur utilisé sur la carte, nous utilisons la même couleur que la géométrie de chaque site (#31).
- Modification du format d'export des visites (#23, #30, #35) :
- Nouveaux en-têtes de colonnes en français mais sans accent ni underscore comme séparateur de mots.
- Les noms des communes sont exportés dans la colonne "_communes_" avec le code INSEE entre parenthèses (#22).
- Les valeurs dans les colonnes à valeurs multiples ("_communes_", "_observateurs_",
"_perturbations_", "_organismes_", "_taxons_cd_nom_") sont désormais séparées par une virgule suivie d'un espace.
- La colonne "_covtaxon_" a été renommée "_taxon_cd_nom_".
- La colonne "_cdhab_" a été renommée "_habitat*cd_hab*_".
- Le code du site a été déplacé vers l'onglet "_Détails_" de la vue de la liste des visites.
- Modification de l'ordre de la liste des taxons (tri croissant) de la fenêtre modale d'édition des visites (#25).
- Modification de l'alignement du bouton de fermeture dans le pied de page de la fenêtre modale de visite qui est maintenant aligné à gauche.
Il ressemble également à un bouton.
- Modification du service Web `GET /export_visit` qui prend désormais en charge plusieurs filtres.
- Formatage de tous les fichiers de code source du backend Python avec _Black_.
- Formatage de tous les fichiers de code source du frontend Angular (ts, html, scss) avec _Prettier_.
- Déplacement du fichier `.prettierrc` vers le répertoire de projet du module supérieur.
- Mise à jour et amélioration du contenu de `.gitignore`.
- ⚠️ Modification de la vue `export_visits` dans le schéma `pr_monitoring_habitat_territory`. Il faut mettre à jour cela manuellement !

### 🐛 Corrigé

- Correction de la suppression des marqueurs de site et de la géométrie affichée sur la carte dans la vue de liste de sites.
Les données affichées sur la carte sont désormais synchronisées avec les données de la liste (#26).
- Correction de la synchronisation entre la ligne sélectionnée dans la vue de la liste des sites et sa carte.
La moitié du temps, elle n'était pas sélectionnable.
- Correction de l'affichage manquant des informations sur le site dans la vue de la liste des visites.
- Correction de la géométrie utilisée dans l'exportation des visites. Utilisez maintenant la géométrie du site et non un maillage kilométrique (#32).
- Correction de l'exportation des visites au format GeoJson qui utilise maintenant le SRID 4326.
- Correction du service Web `GET /sites` qui renvoie désormais correctement les informations sur les sites lorsque des filtres d'organismes ou d'années sont utilisés.
- Correction du service Web `POST /visits`, utilisation correcte du code du module pour ajouter une nouvelle visite (#33).
- Correction de l'utilisation de join et externaljoin dans les requêtes backend.

### 🗑 Supprimé

- Les noms de site ne sont plus présents dans les exportations de visites.
- Suppression de `settings.sample.ini` inutile pour les scripts Bash d'importation.


## [1.0.0] - 2022-09-22

### 🚀 Ajouté

- Ajout du support Alembic.
- Compatibilité avec GeoNature v2.9.2.
- Ajout d'une nouvelle architecture de module ("packagée").
- Remplacement de l'utilisation de l'identifiant par le code du module.
- Tous les scripts d'importation Bash avec leurs fichiers SQL sont déplacés vers le répertoire `bin/`.

### 🔄 Modifié

- Documentation du module mise à jour.


## [1.0.0-beta] - 2022-02-15

Première version stable. Compatibilité avec GeoNature v2.3.2.

### 🚀 Ajouté

- Mise à jour de la compatibilité avec GeoNature v2.3.0
- Ajout des scripts d'importation Bash pour : observations, visites, nomenclatures, habitats, sites, taxons.
- Ajout de la bibliothèque partagée de scripts d'importation de fonctions Bash.
- Ajout de la documentation pour les nouveaux scripts Bash.
- Ajout du script de désinstallation du module.

### 🐛 Corrigé

- Suppression du fichier SQL de vérification inutile.
- Amélioration du script d'installation du module.
- Utilisation de la nouvelle syntaxe utils-flask-sqla.


## [0.0.3] - 2019-05-28

### 🚀 Ajouté

- Refactorisation de l'exportation.


## [0.0.2] - 2019-04-15

### 🐛 Corrigé

- Export corrigé.


## [0.0.1] - 2019-04-11

Version initiale.

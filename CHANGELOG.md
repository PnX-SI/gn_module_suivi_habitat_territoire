# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2024-08-20

### 🚀 Added

- Compatibility with GeoNature 2.14
- Module permissions (CRUVED) declared in alembic branch.
- Add default creation date (now) in `pr_monitoring_habitat_territory.cor_visit_perturbation`

### 🔄 Changed

- Update `install.md`
- Update `requirements.in`
- The `check_user_cruved_visit` and `cruved_scope_for_user_in_module` functions are replaced by the `VisitAuthMixin` class, which contains methods for retrieving user rights on data (CRUVED action + scope).

### 🐛 Fixed

- Fixed Web service `GET /sites` which return now the sites whitout visits.
- Fixed Web service `PATCH /visits/<int:idv>`. We exclude the current patched visit from visits year check.
- Fix the module assets path used for URL (PnX-SI/GeoNature#2957)

## [1.1.0] - 2022-10-22

### 🚀 Added

- Added the memorization between two accesses of the values ​​of the filters of the list of sites view (#28).
- Added a loading indicator on the data tables of the visits list view and the sites list view (#29).
- Added a global spinner to the visits list view.
- Added site UUID display to visit list view.
- Added new columns in visits export (#23) :
  - Visit identifier is exported in "_visit_id_" column.
  - Sites UUID is exported in "_base_site_uuid_" column.
- Added the organization name in parentheses for each observer on the visit list view.
- Added the display of non-habitat taxa present in the database in
  a specific section of the edit visit modal window.
- Added the display of the content of the error message received after submitting
  the form of the visit editing modal window.

### 🔄 Changed

- Municipalities and organisms filters now use an identifier instead of a
  label to retrieve the corresponding visits.
- Changed the initial zoom used for the map of the sites list view. Zoom down.
- Changed display of map legend :
  - Use years number instead of "_year+1_", "_year+2_"...
  - Use distinct colors instead of a graduation of red color : blue, green, yellow, orange and red.
  - Site with recent visit use cold color (blue) and site with old visits use warm color (red).
- Changed the color of the marker used on the map, we use the same color as the geometry of each site (#31).
- Changed visit export format (#23, #30, #35):
  - New columns headers in french but with no accent and underscore as words separator.
  - Municipalities names are exported in "_communes_" column with INSEE code between parenthesis (#22).
  - Values in multiples values columns ("_communes_", "_observateurs_",
    "_perturbations_", "_organismes_", "_taxons_cd_nom_") are now separated by comma follow by a space.
  - "_covtaxon_" column was renamed "_taxon_cd_nom_".
  - "_cdhab_" column was renamed "_habitat*cd_hab*_".
- Moved site code to "_Details_" tab of the visit list view.
- Changed the order of the list of taxa (ascending sort) of the modal window for editing visits (#25).
- Changed the alignment of the close button in the visit modal window footer which is now left-aligned.
  It also looks like a button.
- Changed the `GET /export_visit` web service which now supports multiple filters.
- Formated all Python backend source code files with _Black_.
- Formated all Angular frontend source code files (ts, html, scss) with _Prettier_.
- Moved `.prettierrc` file to top module project directory.
- Updated and improve `.gitignore` content.
- ⚠️ Changed `export_visits` view in `pr_monitoring_habitat_territory` schema. Need to update this manually !

### 🐛 Fixed

- Fixed removing site markers and geometry displayed on the map in site list view.
  The data displayed on the map is now synchronized with the data in the list (#26).
- Fixed synchronization between the line selected in the site list view and its map.
  Half the time it was not selectable.
- Fixed missing display of site information on visit list view.
- Fixed geometry used in visit export. Now use site geometry and not a kilometer mesh (#32).
- Fixed visits export in GeoJson format which now use SRID 4326.
- Fixed Web service `GET /sites` which return now correctly sites infos when organisms or year filters are used.
- Fixed Web service `POST /visits`, correct use of module code to add new visit (#33).
- Fixed use of join and outerjoin in backend queries.

### 🗑 Removed

- Site names are no longer present in visit exports.
- Removed useless `settings.sample.ini` for import Bash scripts.

## [1.0.0] - 2022-09-22

### 🚀 Added

- Added Alembic support.
- Compatibility with GeoNature v2.9.2.
- Added new module architecture ("packaged").
- Replaced use of id by code for module.
- All Bash import scripts with their SQL files move to `bin/` directory.

### 🔄 Changed

- Updated module documentation.

## [1.0.0-beta] - 2022-02-15

First stable version. Compatibility with GeoNature v2.3.2.

### 🚀 Added

- Update compatibility to GeoNature v2.3.0
- Added Bash imports scripts for : observations, visits, nomenclatures, habitats, sites, taxons.
- Added import script shared library of Bash functions.
- Added documentation for new Bash scripts.
- Added uninstall module script.

### 🐛 Fixed

- Removed useless checking SQL file.
- Improved install module script.
- Use new utils-flask-sqla syntax.

## [0.0.3] - 2019-05-28

### 🚀 Added

- Refactorization of export.

## [0.0.2] - 2019-04-15

### 🐛 Fixed

- Fixed export.

## [0.0.1] - 2019-04-11

Initial version.

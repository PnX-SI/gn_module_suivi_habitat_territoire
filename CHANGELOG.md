# CHANGELOG

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [1.1.0] - 2022-10-22

### Added
* Add a loading indicator on the data tables of the visits list view and the sites list view.
* Add a global spinner to the visits list view.
* Add site UUID display to visit list view.
* New columns added in visits export :
  * Visit identifier is exported in "*visit_id*" column.
  * Sites UUID is exported in "*base_site_uuid*" column.
* Add the organization name in parentheses for each observer on the visit list view.
* Add the display of non-habitat taxa present in the database in
a specific section of the edit visit modal window.
* Add the display of the content of the error message received after submitting
the form of the visit editing modal window.

### Changed
* Site list view filters are now remembered between two accesses
* Municipalities and organisms filters now use an identifier instead of a
label to retrieve the corresponding visits.
* Change the initial zoom used for the map of the sites list view. Zoom down.
* Change display of map legend :
  * Use years number instead of "*year+1*", "*year+2*"...
  * Use distinct colors instead of a graduation of red color : blue, green, yellow, orange and red.
  * Site with recent visit use cold color (blue) and site with old visits use warm color (red).
* Change the color of the marker used on the map, we use the same color as the geometry of each site.
* Complete redesign of the export :
  * New columns headers in french but with no accent and underscore as words separator.
  * Municipalities names are exported in "*communes*" column with INSEE code between parenthesis.
  * Values in multiples values columns ("*communes*", "*observateurs*",
  "*perturbations*", "*organismes*", "*taxons_cd_nom*") are now separated by comma follow by a space.
  * "*covtaxon*" column was renamed "*taxon_cd_nom*".
  * "*cdhab*" column was renamed "*habitat_cd_hab_*".
* Move site code to "*Details*" tab of the visit list view.
* Change the order of the list of taxa (ascending sort) of the modal window for editing visits.
* Change the alignment of the close button in the visit modal window footer which is now left-aligned.
It also looks like a button.
* Change the `/export_visit` web service which now supports multiple filters.
* Format all backend Python source code files with *Black*.
* Format all frontend Angular source code files (ts, html, scss) with *Prettier*.
* Move `.prettierrc` file to top module project directory.
* Update and improve `.gitignore` content.
### Fixed
* Fixed removing site markers and geometry displayed on the map in site list view.
The data displayed on the map is now synchronized with the data in the list.
* Fixed synchronization between the line selected in the site list view and its map.
Half the time it was not selectable.
* Fixed missing display of site information on visit list view.
* Fixed geometry used in visit export. Now use site geometry and not a kilometer mesh.
* Fixed visits export in GeoJson format which now use SRID 4326.
* Fixed Web service `GET /sites` which return now correctly sites infos when organisms or year filters are used.
* Fixed Web service `POST /visits`, correct use of module code.

### Removed
* Site names are no longer present in visit exports.
* Remove useless `settings.sample.ini` for import Bash scripts.

## [1.0.0] - 2022-09-22

### Added

* Add Alembic support.
* Compatibility with GeoNature v2.9.2.
* Add new module architecture ("packaged").
* Replace use of id by code for module.
* All Bash import scripts with their SQL files move to `bin/` directory.
* Update module documentation.

## [1.0.0-beta] - 2022-02-15

First stable version. Compatibility with GeoNature v2.3.2.

### Added

* Update compatibility to GeoNature v2.3.0
* Add Bash imports scripts for : observations, visits, nomenclatures, habitats, sites, taxons.
* Add import script shared library of Bash functions.
* Add documentation for new Bash scripts.
* Add uninstall module script.

### Fixed

* Remove useless checking SQL file.
* Improve install module script.
* Use new utils-flask-sqla syntax.

## [0.0.3] - 2019-05-28
### Added

* Refactorization of export.
## [0.0.2] - 2019-04-15
### Fixed

* Fix export.

## [0.0.1] - 2019-04-11

Initial version.

#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import sites script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
Update settings.ini, section "Import sites" before run this script.

     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported sites
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--delete") set -- "${@}" "-d" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxdc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "d") action="delete" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Define global constants and variables
    action="import"

    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${sites_import_log}"

    checkSuperuser
    commands=("psql" "shp2pgsql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Sites import script started at: ${fmt_time_start}"

    if [[ "${action}" = "import" ]]; then
        importSites
    elif [[ "${action}" = "delete" ]]; then
        deleteSites
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function importSites() {
    loadShapeToPostgresql

    printMsg "Insert sites data into gn_monitoring, ref_geo and ${module_schema}"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v sridLocal="${srid_local}" \
            -v sridWorld="${srid_world}" \
            -v moduleSchema="${module_schema}" \
            -v moduleCode="${module_code}" \
            -v sitesTableTmp="${sites_table_tmp}" \
            -v sitesColumnGeom="${sites_column_geom}" \
            -v sitesTypeCode="${sites_type_code}" \
            -v sitesColumnCode="${sites_column_code}" \
            -v sitesColumnType="${sites_column_type}" \
            -v sitesColumnHabitat="${sites_column_habitat}" \
            -v sitesMeshesSource="${sites_meshes_source}" \
            -v importDate="${import_date}" \
            -f "${data_dir}/import_sites.sql"
}

function deleteSites() {
    loadShapeToPostgresql

    printMsg "Delete sites listed in '${sites_shape_path##*/}' SHP file from gn_monitoring, ref_geo and ${module_schema}"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleSchema="${module_schema}" \
            -v sitesTableTmp="${sites_table_tmp}" \
            -v sitesTypeCode="${sites_type_code}" \
            -v sitesColumnCode="${sites_column_code}" \
            -v sitesColumnHabitat="${sites_column_habitat}" \
            -v importDate="${import_date}" \
            -f "${data_dir}/delete_sites.sql"
}

function loadShapeToPostgresql() {
    printMsg "Export sites SHP to PostGis and create sites temporary table « ${module_schema}.${sites_table_tmp} »"
    export PGPASSWORD="${user_pg_pass}"; \
        shp2pgsql -d -s ${srid_local} "${sites_shape_path}" "${module_schema}.${sites_table_tmp}" \
        | psql -h "${db_host}" -U "${user_pg}" -d "${db_name}"
}

main "${@}"

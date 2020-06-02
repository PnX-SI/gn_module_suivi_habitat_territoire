#!/usr/bin/env bash
# Encoding : UTF-8
# SHT install Database script.
#
# Documentation : https://github.com/PnX-SI/gn_module_suivi_habitat_territoire
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
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
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${install_log}"

    checkSuperuser
    commands=("psql" "wget")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "SHT install DB script started at: ${fmt_time_start}"

    #+----------------------------------------------------------------------------------------------------------+
    createModuleSchema
    insertDataRefs
    insertSampleData

    #+----------------------------------------------------------------------------------------------------------+
    displayTimeElapsed
}

function createModuleSchema() {
    printMsg "Create SHT schema into GeoNature database"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleSchema="${module_schema}" \
            -f "${data_dir}/sht_schema.sql"
}

function insertDataRefs() {
    printMsg "Create SHT lists (no values => use import scripts) : meshes, taxons, perturbation"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v taxonsListName="${taxons_list_name}" \
            -v habitatsListName="${habitats_list_name}" \
            -v perturbationsCode="${perturbations_code}" \
            -v perturbationsSrc="${perturbations_src}" \
            -v sitesTypeCode="${sites_type_code}" \
            -v sitesTypeSrc="${sites_type_src}" \
            -f "${data_dir}/sht_data_ref.sql"
}

function insertSampleData() {
    # Include sample data into database
    if [ "${insert_sample_data}" = true ]; then
        printMsg "Insert SHT data sample"

        printMsg "Import nomenclatures data sample"
        bash "${script_dir}/import_nomenclatures.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import taxons data sample"
        bash "${script_dir}/import_taxons.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import habitats data sample"
        bash "${script_dir}/import_habitats.sh" -c "${conf_dir}/install_data_sample.ini" -v

        printMsg "Import sites data sample"
        bash "${script_dir}/import_sites.sh" -c "${conf_dir}/install_data_sample.ini" -v
    else
        printPretty "--> SHT data sample was NOT included in database" ${Gra-}
    fi
}

main "${@}"

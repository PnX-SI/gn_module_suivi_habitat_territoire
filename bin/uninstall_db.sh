#!/usr/bin/env bash
# Encoding : UTF-8
# SHT UNinstall Database script.
# WARNING : all DATA and structure will be removed.
#
# Documentation : https://github.com/PnX-SI/gn_module_suivi_habitat_territoire
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
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
    redirectOutput "${uninstall_log}"

    checkSuperuser
    commands=("psql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "SHT UNinstall DB script started at: ${fmt_time_start}"

    #+----------------------------------------------------------------------------------------------------------+
    printPretty "${Red}ALL data, tables and schema will be destroy. Are you sure to uninstall SHT? ('Y' or 'N')"
    read -r reply
    echo # Move to a new line
    if [[ ! "${reply}" =~ ^[Yy]$ ]];then
        [[ "${0}" = "${BASH_SOURCE}" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
    fi

    #+----------------------------------------------------------------------------------------------------------+
    printMsg "Delete SHT schema and all data linked from GeoNature database"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" \
            -v moduleSchema="${module_schema}" \
            -v moduleCode="${module_code}" \
            -v taxonsListName="${taxons_list_name}" \
            -v habitatsListName="${habitats_list_name}" \
            -v perturbationsCode="${perturbations_code}" \
            -v sitesTypeCode="${sites_type_code}" \
            -f "${data_dir}/sht_uninstall.sql"

    #+----------------------------------------------------------------------------------------------------------+
    displayTimeElapsed
}

main "${@}"

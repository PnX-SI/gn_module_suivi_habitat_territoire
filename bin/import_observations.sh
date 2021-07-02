#!/usr/bin/env bash
# Encoding : UTF-8
# SHT import observations script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
Update settings.ini, section "Import observations" before run this script.
     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported observations 
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "$@"; do
        shift
        case "$arg" in
            "--help") set -- "$@" "-h" ;;
            "--verbose") set -- "$@" "-v" ;;
            "--debug") set -- "$@" "-x" ;;
            "--config") set -- "$@" "-c" ;;
            "--delete") set -- "$@" "-d" ;;
            "--"*) exitScript "ERROR : parameter '$arg' invalid ! Use -h option to know more." 1 ;;
            *) set -- "$@" "$arg"
        esac
    done

    while getopts "hvxdc:" option; do
        case "$option" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="$OPTARG" ;;
            "d") action="delete" ;;
            "?") exitScript "ERROR : parameter '$OPTARG' invalid ! Use -h option to know more." 1 ;;
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
    redirectOutput "${visits_import_log}"

    checkSuperuser
    commands=("psql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Observatgions import script started at: ${fmt_time_start}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    createTmpTables
    importCsvDataByCopy

    if [[ "$action" = "import" ]]; then
        importObservations
    elif [[ "$action" = "delete" ]]; then
        deleteObservations
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function createTmpTables() {
    printMsg "Create temporary tables"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v visitsHasPerturbationsTmpTable="${visits_table_tmp_has_perturbations}" \
            -v visitsHasObserversTmpTable="${visits_table_tmp_has_observers}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -v obsTmpTable="${obs_table_tmp_obs}" \
            -f "${data_dir}/import_obs_tmp_tables.sql"
}

function importCsvDataByCopy() {
    printMsg "Import observations data into tmp tables"
    sudo -n -u ${pg_admin_name} -s \
        psql -d "${db_name}" ${psql_verbosity} \
        -v moduleSchema="${module_schema}" \
        -v visitsTmpTable="${visits_table_tmp_visits}" \
        -v visitsCsvPath="${visits_csv_path}" \
        -v obsTmpTable="${obs_table_tmp_obs}" \
        -v obsCsvPath="${obs_csv_path}" \
        -f "${data_dir}/import_obs_copy.sql"
}

function importObservations() {
    printMsg "Insert observations from temporary data"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v obsTmpTable="${obs_table_tmp_obs}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -f "${data_dir}/import_obs.sql"
}

function deleteObservations() {
    printMsg "Delete observations listed in CSV file"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v obsTmpTable="${obs_table_tmp_obs}" \
            -v visitsTmpTable="${visits_table_tmp_visits}" \
            -f "${data_dir}/delete_obs.sql"
}

main "${@}"

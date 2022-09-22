#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import habitats script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
Update settings.ini, section "Import visits" before run this script.
     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported habitats
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
    redirectOutput "${habitats_import_log}"

    checkSuperuser
    commands=("psql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Habitats import script started at: ${fmt_time_start}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    loadCsvInTmpTables

    if [[ "$action" = "import" ]]; then
        importHabitats
    elif [[ "$action" = "delete" ]]; then
        deleteHabitats
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function loadCsvInTmpTables() {
    printMsg "Load CSV habitats data in temporary table"
    sudo -n -u ${pg_admin_name} -s \
        psql -d "${db_name}" ${psql_verbosity} \
            -v dbUserName="${user_pg}" \
            -v moduleSchema="${module_schema}" \
            -v habitatsTmpTable="${habitats_table_tmp}" \
            -v habitatsCsvPath="${habitats_csv_path}" \
            -f "${data_dir}/import_habitats_csv.sql"
}

function importHabitats() {
    printMsg "Insert habitats from temporary data"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v habitatsTmpTable="${habitats_table_tmp}" \
            -v moduleCode="${module_code}" \
            -v habitatsListName="${habitats_list_name}" \
            -v importDate="${import_date}" \
            -f "${data_dir}/import_habitats.sql"
}

function deleteHabitats() {
    printMsg "Delete habitats listed in CSV file"
    export PGPASSWORD="${user_pg_pass}"; \
        psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
            -v moduleSchema="${module_schema}" \
            -v habitatsTmpTable="${habitats_table_tmp}" \
            -v moduleCode="${module_code}" \
            -v habitatsListName="${habitats_list_name}" \
            -v importDate="${import_date}" \
            -f "${data_dir}/delete_habitats.sql"
}

main "${@}"

#!/usr/bin/env bash
# Encoding : UTF-8
# SFT import nomenclatures script.
set -eo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE) [options]
Update settings.ini, section "Import nomenclatures" before run this script.
     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported nomenclatures
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
    redirectOutput "${nomenclatures_import_log}"

    checkSuperuser
    commands=("psql" "csvtool")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Nomenclatures import script started at: ${fmt_time_start}"

    # Manage verbosity
    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
    fi

    if [[ "$action" = "import" ]]; then
        importNomenclatures
    elif [[ "$action" = "delete" ]]; then
        deleteNomenclatures
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function importNomenclatures() {
    local head="$(csvtool head 1 "${nomenclatures_csv_path}")"
    printMsg "Import nomenclatures list into « ref_nomenclatures.t_nomenclatures »"
    local tasks_done=0
    local tasks_count="$(($(csvtool height "${nomenclatures_csv_path}") - 1))"
    while IFS= read -r line; do
        local type_code="$(printf "$head\n$line" | csvtool namedcol type_nomenclature_code - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local code="$(printf "$head\n$line" | csvtool namedcol cd_nomenclature - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local mnemonique="$(printf "$head\n$line" | csvtool namedcol mnemonique - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local label="$(printf "$head\n$line" | csvtool namedcol label_default - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local definition="$(printf "$head\n$line" | csvtool namedcol definition_default - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local label_fr="$(printf "$head\n$line" | csvtool namedcol label_fr - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local definition_fr="$(printf "$head\n$line" | csvtool namedcol definition_fr - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local broader="$(printf "$head\n$line" | csvtool namedcol cd_nomenclature_broader - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local hierarchy="$(printf "$head\n$line" | csvtool namedcol hierarchy - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

        printVerbose "Inserting nomenclature: '${code}' from '${type_code}'"
        export PGPASSWORD="${user_pg_pass}"; \
            psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
                -v typeCode="${type_code}" \
                -v code="${code}" \
                -v mnemonique="${mnemonique}" \
                -v label="${label}" \
                -v labelFr="${label_fr}" \
                -v definition="${definition}" \
                -v definitionFr="${definition_fr}" \
                -v broader="${broader}" \
                -v hierarchy="${hierarchy}" \
                -f "${data_dir}/import_nomenclatures.sql"

        if ! [[ -n ${verbose-} ]]; then
            (( tasks_done += 1 ))
            displayProgressBar $tasks_count $tasks_done "inserting"
        fi
    done < <(stdbuf -oL csvtool drop 1 "${nomenclatures_csv_path}")
    echo
}

function deleteNomenclatures() {
    printMsg "Delete child nomenclatures listed in CSV file from « ref_nomenclatures.t_nomenclatures »"
    parents=()
    deleteChildNomenclatures
    deleteParentNomenclatures
}

function deleteChildNomenclatures() {
    local head="$(csvtool head 1 "${nomenclatures_csv_path}")"
    local tasks_done=0
    local tasks_count="$(($(csvtool height "${nomenclatures_csv_path}") - 1))"
    while IFS= read -r line; do
        local type_code="$(printf "$head\n$line" | csvtool namedcol type_nomenclature_code - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local code="$(printf "$head\n$line" | csvtool namedcol cd_nomenclature - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
        local broader="$(printf "$head\n$line" | csvtool namedcol cd_nomenclature_broader - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

        if [[ "${broader}" == "0" ]]; then
            parents+=("${type_code}|${code}")
        else
            printVerbose "Deleting child nomenclatures: '${code}' from '${type_code}'"
            export PGPASSWORD="${user_pg_pass}"; \
                psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
                    -v typeCode="${type_code}" \
                    -v code="${code}" \
                    -f "${data_dir}/delete_nomenclatures.sql"
        fi

        if ! [[ -n ${verbose-} ]]; then
            (( tasks_done += 1 ))
            displayProgressBar $tasks_count $tasks_done "deleting childs"
        fi
    done < <(stdbuf -oL csvtool drop 1 "${nomenclatures_csv_path}")
    echo
}

function deleteParentNomenclatures() {
    printMsg "Delete parent nomenclatures listed in CSV file from « ref_nomenclatures.t_nomenclatures »"
    local tasks_done=0
    local tasks_count="${#parents[@]}"
    for data in "${parents[@]}";do
        local type_code="${data%|*}"
        local code="${data#*|}"
        printVerbose "Deleting parent nomenclatures: '${code}' from '${type_code}'"
        export PGPASSWORD="${user_pg_pass}"; \
            psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity} \
                -v typeCode="${type_code}" \
                -v code="${code}" \
                -f "${data_dir}/delete_nomenclatures.sql"

        if ! [[ -n ${verbose-} ]]; then
            (( tasks_done += 1 ))
            displayProgressBar $tasks_count $tasks_done "deleting parents"
        fi
    done
}

main "${@}"

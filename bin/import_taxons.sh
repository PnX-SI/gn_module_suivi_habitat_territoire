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
Update settings.ini, section "Import taxons" before run this script.

     -h | --help: display this help
     -v | --verbose: display more information on what script is doing
     -x | --debug: enable Bash mode debug
     -c | --config: path to config file to use (default : config/settings.ini)
     -d | --delete: delete all imported taxons
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
    redirectOutput "${taxons_import_log}"

    checkSuperuser
    commands=("psql" "csvtool")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "Taxons import script started at: ${fmt_time_start}"

    if [[ -n ${verbose-} ]]; then
        readonly psql_verbosity="${psql_verbose_opts-}"
    else
        readonly psql_verbosity="${psql_quiet_opts-}"
        readonly tasks_count="$(($(csvtool height "${taxons_csv_path}") - 1))"
        tasks_done=0
    fi

    if [[ "${action}" = "import" ]]; then
        importTaxons
    elif [[ "${action}" = "delete" ]]; then
        deleteTaxons
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Show time elapsed
    displayTimeElapsed
}

function importTaxons() {
    printMsg "Import taxons list into « taxonomie.bib_noms » and « taxonomie.cor_nom_liste »"

    local head="$(csvtool head 1 "${taxons_csv_path}")"
    stdbuf -oL csvtool drop 1 "${taxons_csv_path}"  |
        while IFS= read -r line; do
            local name_id="$(printf "${head}\n${line}" | csvtool namedcol cd_nom - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
            local name_ref="$(printf "${head}\n${line}" | csvtool namedcol cd_ref - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
            local name="$(printf "${head}\n${line}" | csvtool namedcol name - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
            local comment="$(printf "${head}\n${line}" | csvtool namedcol comment - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

            printVerbose "Inserting taxon: '${name_id}' (${name})"
            export PGPASSWORD="${user_pg_pass}"; \
                psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity-} \
                    -v nameId="${name_id}" \
                    -v nameRef="${name_ref}" \
                    -v name="${name}" \
                    -v taxonsListName="${taxons_list_name}" \
                    -v comment="${comment}" \
                    -f "${data_dir}/import_taxon.sql"

            if ! [[ -n ${verbose-} ]]; then
                (( tasks_done += 1 ))
                displayProgressBar ${tasks_count} ${tasks_done} "inserting"
            fi
        done
    echo
}

function deleteTaxons() {
    printMsg "Delete taxons listed in CSV file from  « taxonomie.cor_nom_liste » (not in « taxonomie.bib_noms »)"

    local head="$(csvtool head 1 "${taxons_csv_path}")"
    stdbuf -oL csvtool drop 1 "${taxons_csv_path}"  |
        while IFS= read -r line; do
            local name_id="$(printf "${head}\n${line}" | csvtool namedcol cd_nom - | sed 1d | sed -e 's/^"//' -e 's/"$//')"
            local name="$(printf "${head}\n${line}" | csvtool namedcol name - | sed 1d | sed -e 's/^"//' -e 's/"$//')"

            printVerbose "Deleting taxon: '${name_id}' (${name})"
            export PGPASSWORD="${user_pg_pass}"; \
            psql -h "${db_host}" -U "${user_pg}" -d "${db_name}" ${psql_verbosity-} \
                -v taxonsListName="${taxons_list_name}" \
                -v nameId="${name_id}" \
                -f "${data_dir}/delete_taxons.sql"

            if ! [[ -n ${verbose-} ]]; then
                (( tasks_done += 1 ))
                displayProgressBar ${tasks_count} ${tasks_done} "deleting"
            fi
        done
    echo
}

main "${@}"

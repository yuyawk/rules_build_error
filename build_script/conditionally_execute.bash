#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOS >&2
Wrapper to conditionally execute the command.

With the option '-f', this script can receive arbitrary number of files.
If any of them is an empty file, this script exits successfully
without executing the command.

Usage: $0 [OPTIONS] COMMAND

OPTIONS
    -i
        Ignore error when executing the command.
    -f FILE_TO_CHECK
        Successfully exit if the file is empty
    -h
        Show usage and exit
    -e STDOUT_FILE
        A file path to write stderr message
    -o STDOUT_FILE
        A file path to write stdout message
    -m MESSAGE
        Message when the command fails
    -n NEW_FILE_PATH
        If specified, create a new empty file before executing the command

COMMAND
    Executed if there's no empty file given with '-f'.
EOS
}

exit_if_empty_file() {
    # Exit if the argument is a empty text file
    #
    # Args:
    #   $1: file path
    local file_path
    file_path=$1

    if [[ ! -f "${file_path}" ]]; then
        echo "ERROR: ${file_path} does not exist" >&2
        exit 1
    fi
    if [[ ! -s "${file_path}" ]]; then
        # File is empty: exit successfully
        exit 0
    fi
}

files_to_check=()
files_to_touch=()
ignore_error="false"
error_message="ERROR: execution failed"

while getopts "e:f:him:n:o:" opt; do
    case "${opt}" in
        e)
            stderr_file="${OPTARG}"
        ;;
        f)
            files_to_check+=("${OPTARG}")
        ;;
        h)
            usage
            exit 0
        ;;
        i)
            ignore_error="true"
        ;;
        m)
            error_message="${OPTARG}"
        ;;
        n)
            files_to_touch+=("${OPTARG}")
        ;;
        o)
            stdout_file="${OPTARG}"
        ;;
    esac
done
shift $((OPTIND -1))

# Make sure the required files are touched before exiting
if [[ "${#files_to_touch[@]}" -gt 0 ]]; then
    trap 'touch "${files_to_touch[@]}"' EXIT
fi

if [[ "${#files_to_check[@]}" -gt 0 ]]; then
    for file_to_check in "${files_to_check[@]}"; do
        exit_if_empty_file "${file_to_check}"
    done
fi

if [[ "${ignore_error}" == "true" ]]; then
    "$@" >"${stdout_file:-"/dev/null"}" 2>"${stderr_file:-"/dev/null"}" || true
    echo "StdEut:"
    cat "${stdout_file:-"/dev/null"}" >&2
    echo "StdErr:"
    cat "${stderr_file:-"/dev/null"}" >&2
else
    if ! "$@" >"${stdout_file:-"/dev/null"}" 2>"${stderr_file:-"/dev/null"}" ; then
        echo "${error_message}"
        exit 1
    fi
fi

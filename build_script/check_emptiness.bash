#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<EOS >&2
Check if any of the files are empty.

Usage: $0 [OPTIONS]

OPTIONS
    -f FILE_TO_CHECK
        Successfully exit if the file is empty
    -h
        Show usage and exit
    -m MESSAGE
        Error message when no files are empty
    -n NEW_FILE_PATH
        If specified, create a new empty file
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
error_message="ERROR: No files are empty"

while getopts "f:hm:n:" opt; do
    case "${opt}" in
        f)
            files_to_check+=("${OPTARG}")
        ;;
        h)
            usage
            exit 0
        ;;
        m)
            error_message="${OPTARG}"
        ;;
        n)
            files_to_touch+=("${OPTARG}")
        ;;
    esac
done
shift $((OPTIND -1))

# Make sure the required files are touched before exiting
if [[ "${#files_to_touch[@]}" -gt 0 ]]; then
    trap 'touch "${files_to_touch[@]}"' EXIT
fi

for file_to_check in "${files_to_check[@]}"; do
    exit_if_empty_file "${file_to_check}"
done

# Exit with error if there's no empty file
echo "${error_message}" >&2
exit 1

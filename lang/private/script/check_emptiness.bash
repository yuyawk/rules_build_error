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
        If specified, create a new empty file before exiting the script
EOS
}

exit_if_containing_an_empty_file() {
    # Exit if the arguments contains an empty file
    #
    # Args:
    #   $@: file paths
    local file_paths
    local file_path
    file_paths=("$@")

    for file_path in "${file_paths[@]}"; do
        if [[ ! -f "${file_path}" ]]; then
            echo "ERROR: ${file_path} does not exist" >&2
            exit 1
        fi
    done

    for file_path in "${file_paths[@]}"; do
        if [[ ! -s "${file_path}" ]]; then
            # File is empty: exit successfully
            exit 0
        fi
    done
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

if [[ "${#files_to_check[@]}" -gt 0 ]]; then
    exit_if_containing_an_empty_file "${files_to_check[@]}"
fi

# Exit with error if there's no empty file
echo "${error_message}" >&2
exit 1

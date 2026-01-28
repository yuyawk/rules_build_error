set -euo pipefail

usage() {
    cat <<EOS >&2
Try building the code.

With the option '-f', this script can receive arbitrary number of files.
If any of them is an empty file, this script exits successfully
without executing the build command.

Even if the build command fails, this script won't exit with an error.

Note that this script is supposed to be invoked by 'ctx.actions.run_shell'.
Usage: bash -c '\$@' '' $0 [OPTIONS] COMMAND

OPTIONS
    -f FILE_TO_CHECK
        Successfully exit if the file is empty
    -h
        Show usage and exit
    -e STDOUT_FILE
        A file path to write stderr message
    -o STDOUT_FILE
        A file path to write stdout message
    -n NEW_FILE_PATH
        If specified, create a new empty file with 'touch' before exiting the script.

COMMAND
    Build command.
    Executed if there's no empty file given with '-f'.
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
stdout_file="/dev/null"
stderr_file="/dev/null"

while getopts "e:f:hn:o:" opt; do
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
    trap 'for file in "${files_to_touch[@]}"; do [[ ! -f "${file}" ]] && > "${file}"; done' EXIT
fi

if [[ "${#files_to_check[@]}" -gt 0 ]]; then
    exit_if_containing_an_empty_file "${files_to_check[@]}"
fi

"$@" >"${stdout_file}" 2>"${stderr_file}" || true

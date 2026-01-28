set -euo pipefail

usage() {
    cat <<EOS >&2
Check each message file.

Exits with an error if the pattern is not found in the message file.

Note that this script is supposed to be invoked by 'ctx.actions.run_shell'.
Usage: bash -c '\$@' '' $0 MATCHER PATTERN_FILE MESSAGE_FILE [MARKER_FILE ...]

MATCHER
    Executable to check if the pattern string is inside the message file

PATTERN_FILE
    Text file containing a pattern string

MESSAGE_FILE
    Text file containing a message

MARKER_FILE ...
    Empty text files are created at the specified paths before exiting the script
EOS
}

if [ "$#" -lt 3 ]; then
  echo "ERROR: Incorrect number of arguments" >&2
  usage
  exit 1
fi

matcher=$1
pattern_file=$2
message_file=$3
shift 3

files_to_touch=("$@")

# Make sure the required files are touched before exiting
if [[ "${#files_to_touch[@]}" -gt 0 ]]; then
    trap 'for file_to_touch in "${files_to_touch[@]}"; do [[ ! -f "${file_to_touch}" ]] && > "${file_to_touch}"; done' EXIT
fi

for file_path in "${matcher}" "${pattern_file}" "${message_file}"; do
    if [[ ! -f "${file_path}" ]]; then
        echo "ERROR: ${file_path} does not exist" >&2
        exit 1
    fi
done

if [[ ! -s "${pattern_file}" ]]; then
    echo "ERROR: Cannot use an empty pattern string" >&2
    exit 1
fi

if ! "${matcher}" "${pattern_file}" "${message_file}" ; then
    echo "Pattern '$(cat "${pattern_file}")' is not found in the message file '${message_file}' with the matcher '${matcher}'." >&2
    echo "" >&2
    echo "---------- Message: BEGIN ----------" >&2
    cat "${message_file}" >&2
    echo "---------- Message:  END  ----------" >&2
    echo "" >&2
    exit 1
fi

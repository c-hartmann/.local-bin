#! /bin/bash

# TODO this should be able to read from stdin as any good *x command line processor
# DONE

set -u

FROM="ISO-8859-1"
TO="UTF-8"

_error_exit ()
{
	printf '%s\n' "$1" >&2
	exit 1
}

_usage ()
{
	_error_exit "usage: ${0##*/} iso-text-file [iso-text-file]..."
}

# test $# -ge 1 || _usage

if [[ $# -eq 0 ]]; then
	iconv -f $FROM -t $TO
else
	for SRC in "$@"; do
		filename="${SRC%.*}"
		extension="${SRC##*.}"
		iconv -f $FROM -t $TO "${SRC}" > "${filename}-utf8.${extension}"
	done
fi



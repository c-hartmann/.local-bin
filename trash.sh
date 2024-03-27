#!/bin/bash
# vim: noexpandtab:ts=4
#---------------------------------------------
#   xdg-trash
#
#   Utility script to manipulate trash directory and contents
#   on XDG compliant systems as specified in:
#
#   https://specifications.freedesktop.org/trash-spec/trashspec-latest.html
#
#   Refer to the usage() function below for usage.
#
#   Copyright 2023, Christian Hartmann <hartmann.christian@gmail.com>
#
#   LICENSE:
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included
#   in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
#   OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#   OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#   ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#   OTHER DEALINGS IN THE SOFTWARE.
#
#---------------------------------------------

TODO=()
TODO+=( "handle rooted .Trash-$UID directories" )
TODO+=( "handle roorted metadata and directorysizes file (see: MyBook)" )

version='0.1.1'

# OTHER (and 'stolen' some ideas from):
# https://github.com/cjbassi/rubbish (has a command file(s) syntax)
# https://github.com/sindresorhus/trash-cli (command is 'trash') (suports: alias rm=trash)
# https://github.com/alphapapa/rubbish.py (has very nice options on clearing trash)
# https://github.com/andreafrancia/trash-cli (nice listing of trash items)

# SEE ALSO:
# https://github.com/sindresorhus/guides/blob/main/how-not-to-rm-yourself.md#safeguard-rm

# RECOMENDED ALIENS:
# alias trash="xdg-trash put"
# alias delete="xdg-trash put"
# alias undelete="xdg-trash get" || alias undelete="xdg-trash restore"

# IDEAS:
# trash list command shall be able to order by size (date is an obvious variant)
# .. rely on DeletionDate only (heavy costly)
# install this with a simple curl URL command from any directory (required sudo is handled by policy kit?)

# TODO:
# command completion
# do we require bash or is sh good enough?
# naming: 'delete' or 'trash' (it) ? both are reasonable,
# .. but delete IS the most used term in the spec!
# .. if using a command like naming as rubbish does, trash is more reasonable
# read the specification (e.g. on date format: real files stop after the seconds)
# .. DeletionDate=2023-06-14T14:23:13  <<<<!
# use other xdg-* commands as a template
# respect - if doable - user's choice of confirmation on deleting
# full path name requires special treatment (e.g. spaces convert to %20)
# .. [Trash Info]: Path=/home/christian/Accounts%20und%20Passw%C3%B6rter
# should this be an XDG command?
# should we have a "list" mode?
# should we have a "undelete" mode?
# should we have a "final delete" mode (aka 'clear')?
# should we have a rm(1) replacement mode? (i.e. rm might be aliased to delete
# .. but instead of removing files immediatly they are just moved to trash ;)
# .. is $0 'rm' if aliased?
# howto: check for commands (and it's default 'put') resonable and save?
# .. if a command id present it is always $1, or not? users are dump, so ...
# .. go for options first, remove these and the rest is either a command or a
# .. file. what if we try to delete a file names as a command !?!?
# check on existence of trash directory (fail if not present)
# trap cat and mv and exit with code if we fail?
# exit codes:
# 1: generic fail
# 2: failed on creating info or moving one file
# 9: no trash directory or target directories inside


# DEFINITIONS: (from XDG Spec)
# Trash — the storage of files that were trashed (“deleted”) by the user.
# Trashing — a “delete” operation in which files are transferred into the Trash can.
# Erasing — an operation in which files (possibly already in the Trash can) are removed (unlinked) from the file system.
# A “shredding” operation, physically overwriting the data, may or may not accompany an erasing operation
# Original location — the name and location that a file (currently in the trash) had prior to getting trashed.
# Original filename — the name that a file (currently in the trash) had prior to getting trashed.
# “Home trash” directory — a user's main trash directory. Its name and location is defined in this document.

# The Trash:  where meta info and files go
# Spec: $XDG_DATA_HOME/Trash - not set on KDE and Gnome
# at least virgin Gnome (and Pop) do not have this directory.
# .. It is initialized via a "To Trash" operation in file manager.
# .. (Including the two subdirectories) and so will we ...
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-0.6.html
# .. $XDG_DATA_HOME defines the base directory relative to which user specific data files should be stored.
# .. If $XDG_DATA_HOME is either not set or empty, a default equal to $HOME/.local/share should be used.
xdg_data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
trash_dir="${xdg_data_home}/Trash"
trash_dir_mode=700

# https://github.com/sindresorhus/trash-cli (command is 'trash') (suports: alias rm=trash)
# https://github.com/alphapapa/rubbish.py (has very nice options on clearing trash)
# https://github.com/andreafrancia/trash-cli (nice listing of trash items)

usage()
{
cat << _USAGE
xdg-trash - command line tool for deleting files to trash

Synopsis

xdg-trash put      delete file(s) to trash (default if command is omitted)
xdg-trash get      undelete files from trash (requires trash file name(s))
xdg-trash list     list files in trash (with trash file name(s))
xdg-trash search   search for files in trash by glob or regular expression
xdg-trash purge    unlink deleted files (trash cleaning for individual file(s))
xdg-trash clean    unlink all deleted files in trash
xdg-trash ...

xdg-trash --help
xdg-trash --regular | -r
xdg-trash trash-dir <any-other-trash-dir>
xdg-trash --version

_USAGE
}

# fail with reasonable information
error_exit()
{
	local _error_no=$1
	case ${_error_no} in
		1 )
			:
			;;
		2 )
			:
			;;
		3 )
			printf '%s\n' 'operation impossible:' $2
			exit $_error_no
			;;
		9 )
			printf '%s\n' 'unknown command:' $2
			exit $_error_no
			;;
		99 )
			printf '%s\n' 'internal error'
			exit $_error_no
			;;
		* )
			printf '%s\n' 'unkwon internal error' >&2
			exit 99
			;;
	esac
}

error_skip()
{
	local _file="$1"
	printf '%s: %s\n' "skipped operation on:" "$_file"
}

# DRAFT
get_timestamps_or_iso_times_from_human_key_words()
{
	local _key_word="$1"
	case "${_key_word}" in
		"yesterday" )
			:
			;;
	esac
}

# TODO: shall this function have a KDE detection? (so far the only one, that uses a ' (N)' notation to create unique names
# TODO: check if all (mayor) DEs use this directory scheme:
# KDE: check (' (N)' notation)
# Gnome: check ('.N' notation)
# Cinnamon: check ('.N' notation)
# MATE: check (with Mint) ('.N' notation)
# XFCE: check (with Mint) ('.N' notation)
# LXQt: check (with Lubuntu) ('.N' notation)
# Pantheon: check (with Elementary OS) (random uuid like extension to file and info)
# DEEPIN: check ('.N' notation)
# LXDE: check (with Fedora Spin) ('.N' notation)
# Trinity: check (with q4os) (on doubles _1 is extended first)
# enlightenment
# Budgie (Solus,Ubuntu) ('.N' notation)
# Unity
# Cosmic (Pop!_OS) check ('.N' notation)
get_next_unique_file_name()
{
	# see:
	# https://unix.stackexchange.com/questions/507188/extract-substring-according-to-regexp-with-sed-or-grep
	local _base_name="$1"
	# at least we have one file with that name.
	# so get the "latest" of the same name with trailing seperator (' (.+)'
	local _last_numerator=$(
		cd "${trash_dir}/files"
		if [ $XDG_SESSION_DESKTOP == KDE ]; then
			# KDE style with parentheses
			ls -1 "${_base_name}"\ * 2>/dev/null | sed "s/${_base_name} (\(.*\))/\1/" | sort -n | tail -1
 		else
			# all the other environments ('+' requires to be escaped)
			ls -1 "${_base_name}"\.* 2>/dev/null | sed "s/${_base_name}\.\([[:digit:]]\+\)/\1/" | sort -n | tail -1
		fi
	)
  	[ -z "${_last_numerator}" ] && _last_numerator=1
  	local _next_numerator=$(expr $_last_numerator + 1)
  	printf '%s' "${_base_name}.$_next_numerator"
}

deletion_date()
{
	# creates like 2023-07-31T15:43:48
	date +%F\T%T
}

init_trash_storage()
{
	mkdir --mode=$trash_dir_mode "${trash_dir}"
	mkdir --mode=$trash_dir_mode "${trash_dir}/files"
	mkdir --mode=$trash_dir_mode "${trash_dir}/info"
}

# and the credits for urlencode and urldecode goes to:
# https://github.com/sixarm/urldecode.sh
# found via:  https://unix.stackexchange.com/questions/159253/decoding-url-encoding-percent-encoding

urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}

urldecode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# if first argument is not one of the restricted words, it is a command
# or a file (if no command is given and defaults to 'put').
# if (first) file is named as one of these restricted command words,
# a command is *required*. in all others usages 'put' is the not
# required default command. all the restricted words and therefore
# allowed commands are taken from the xdg trash specification.
# the delete and recover from trash operation SHOULD be able to find
# files by a glob expression.
# the list/search (arn't these the same?) SHOULD support to sort by
# size and deletion date
# from https://github.com/alphapapa/rubbish.py:
# $ rubbish list --size --trashed-before today
restricted_command_words=( \
	'put' \
	'delete' \
	'trash' \
	'get' \
	'undelete' \
	'recover' \
	'restore' \
	'erase' \
	'remove' \
	'rm' \
	'unlink' \
	'shred' \
	'clear' \
	'clean' \
	'empty' \
	'list' \
)

# NOTE: evaluate as an array ? (${_command_options[@]})
valid_options_long=(
	'help' \
	'trash-dir' \
	'dry' \
	'dry-run' \
	'sort-by-deletion-date' \
	'sort-by-file-size' \
	'reverse' \
	'recursive' \
	'long-listing' \
	'delete-interactive' \
	'version' \
	'usage' \
	'rm' \
	'rm-alias'
)

valid_options_short=(
	'h' \
	'd' \
	't' \
	's' \
	'S' \
	'r' \
	'R' \
	'l' \
	'i' \
	'v' \
	'u'
)

trash_clear()
{
	# TODO: what about dot files? exclude .directory?
	rm -rf "${trash_dir}/files/*"
}

trash_list()
{
	# echo "( cd "${trash_dir}/files"; ls -1 $@ )"
	# option sort_by_file_size: add -S to ls command
	# --time-style=TIME_STYLE

	# TODO:
# 				if [ "$@" == "$_node" ]; then
# 				echo "no match on: $@"
# 				error_skip "$_node"

	local _ls_default_options=' --human-readable -G -g --group-directories-first --classify -v --format=single-column' # --time-style=long-iso
	local _ls_directory_option='--directory'
	(
		cd "${trash_dir}/files"
		printf 'workdir: %s\n' "$PWD"
		# no directory option without given names or globs
		if [ $# -eq 0 ]; then
			printf 'info:%s\n' 'no expression given'
			_ls_directory_option=''
		fi
# 		printf 'listing: %s\n' "$@"
# 		ls "$_ls_directory_option" --human-readable -G -g --group-directories-first --classify -v --time-style=long-iso --format=single-column "$@" 2>/dev/null
		eval /bin/ls $_ls_default_options $_ls_directory_option "$@" # 2>/dev/null
	)
}

# NOTE: erasing from trash shall not fail on non-existing file or info
# NOTE: there might be no need to test for a glob expression! (at least
#       the returned output of get___nodes will be as the input if it
#       is *no* glob expression
# NOTE: see man rm
#     > -I
#     > --interactive[=WHEN]
#     > --interactive[=WHEN]
trash_erase()
{
	# NOTE: "$@" is a list of names as the user would see in trash:/
	# NOTE: name is either a file- or directory name (-> rm rf)
	# NOTE: no names -> no operation
	if [ $# -eq 0 ]; then
		printf 'info:%s\n' 'operation not doable'
		error_exit 9
	fi
	local _ls_default_options=' --human-readable -G -g --group-directories-first --classify -v --format=single-column' # --time-style=long-iso
	local _ls_directory_option='--directory'
	(
		cd "${trash_dir}/files"
# 		printf 'workdir: %s\n' "$PWD"
 		eval _all_nodes=( $(printf ' "%s" ' $@) )
# 		echo ${_all_nodes[@]}
# 		echo ${#_all_nodes[@]}
		for _node in "${_all_nodes[@]}"; do
			if [ "$@" == "$_node" ]; then
				echo "no match on: $@"
				error_skip "$_node"
			else
				printf 'deleting node: %s\n' "$_node"
#  				/bin/ls $_ls_default_options $_ls_directory_option "../files/${_node}" # temporary!
#  				/bin/ls $_ls_default_options $_ls_directory_option "../info/${_node}.trashinfo" # temporary!
				_file="../files/${_node}"
				_info="../info/${_node}.trashinfo"
				test -e "${_file}" && /bin/rm --recursive --verbose "${_file}"
				test -e "${_info}" && /bin/rm --recursive --verbose "${_info}"
#  				echo /bin/rm -rf "../files/${_node}"
#  				echo /bin/rm -rf "../info/${_node}.trashinfo"
			fi
		done
	)
}

get_original_path() # from info
{
	local _name="$1"
	local _trash_info="$trash_dir/info/${_name}.trashinfo"
}

get_deletion_date() # from info
{
	local _name="$1"
	local _trash_info="$trash_dir/info/${_name}.trashinfo"
}

get_top_ls_directory_option()
{
	local _path="$1"
	local _top_dir=${_path%%/*}
	# stop on internal error (e.g. if path starts with a '/')
	[ -z "${_top_dir}" ] && error_exit 99 'internal error in get_top_ls_directory_option()'
	printf '%s' "${_top_dir}"
}

# NOTES:
# undeleting from trash shall not fail on non-existing file or info
trash_get___undelete()
{
	# argument is either a simple basename or a relativ path. in case it
	# is a path the directory/-ies part MUST exist in original location.
	# a simple name is either a file or a directoy.
	local _trash_node="$1"
	# we need a file name
	local _base_name="$(basename "$_trash_node")"
	# get original path first (TODO: this fails for files within a directory)
	if [ "${_base_name}" == "${_trash_node}" ]; then
		_original_path="$(urldecode "$(get_original_path "${_base_name}")")"
		# move file now and remove info
		mv "$_trash_node" "$_original_path" && rm "${_base_name}"
	else
		# get top directory (all before first '/') in _trash_node
		_top_dir="$(get_top_ls_directory_option "${_trash_node}")"
		# get original path from top directory
		_original_path="$(urldecode "$(get_original_path "${_top_dir}")")"
		# get the complete directory part of path
		_dir_path="$(dirname "${_original_path}")"
		# create path (= dir_name) in original location
		mkdir -p "${_dir_path}"
		# mv file to original location + directory part
		mv "${_trash_node}" "${_dir_path}"
	fi
}

trash_put()
{
	# meta infos requires a deletion date. getting this once and now is good enough
	local _deletion_date=$(deletion_date)
	# treat files to delete individualy
	for _node in $@; do
		# meta information requires also a full path name
		dir_name=$(dirname "$_node")
		base_name=$(basename "$_node")
		# TODO: check for topdir/.Trash ...
# 		top_dir=$(df --local --output=target $_node | tail -1)
# 		top_dir=$(stat -c %m -- "$_node")
# 		if [ -d "${top_dir}/.Trash" -a -w "${top_dir}/.Trash" ]; then
# 			trash_dir="${top_dir}/.Trash" # .Trash-1000 seems to be another usual name
# 		fi
		if test ! -w "${trash_dir}/files" -o ! -w "${trash_dir}/info"; then
			error_exit 3 "writing to trash"
		fi
		# if file/directory does not exists in trash already, use original name,
		# otherwise get a new unique name
		if test ! -e "${trash_dir}/files/${base_name}"; then
			target_name="${base_name}"
		else
			target_name="$(get_next_unique_file_name "$base_name")"
		fi
		# skip if file/directory exists with original or the new name
		if test -e "${trash_dir}/files/${target_name}"; then
			error_internal "${dir_name}/${base_name}"
			continue
		fi
		# skip if original file/directory is not deleteable or not existing
		if test ! -w "${dir_name}/${base_name}"; then
			error_skip "${dir_name}/${base_name}"
			continue
		fi
		echo trashing: $file >&2
		# the indentation here requires tab characters (spaces will be printed unremoved)
		cat >"${trash_dir}/info/${target_name}.trashinfo" \
<<_TRASHINFO
		[Trash Info]
		Path=$(urlencode "${dir_name}/${base_name}")
		DeletionDate=${_deletion_date}
_TRASHINFO
		mv ${node} "${trash_dir}/files/${target_name}"
	done
}

get___nodes()
{
	local _glob="$1"
}

trash_get()
{
	# NOTE: der test auf glob ist möglicherweise gefährlicher unsinn
	# there might be many on command line and some might be defined via a glob
	# but all are assumed to be pathless names. are relative path names allowed?
	for _node in "$@"; do
		_is_glob=(is_glob "$_node")
		if ! $_is_glob; then
			# simple undelete of a single file
			trash_get___undelete "$_n"
		else
			# apply glob and get a list of individual files to loop over
			declare -a _nodes=$(get___nodes "$_node")
			for _n in "${_nodes[@]}"; do
				trash_get___undelete "$_n"
			done
		fi
	done
}

# from the spec:
# The “home trash” SHOULD function as the user's main trash directory. Files
# that the user trashes from the same file system (device/partition) SHOULD
# be stored here (see the next section for the storage details). A “home trash”
# directory SHOULD be automatically created for any new user. If this directory
# is needed for a trashing operation but does not exist, the implementation
# SHOULD automatically create it, without any warnings or delays.
# init trash (directories) if there is none
test -d "${trash_dir}" || init_trash_storage

# TODO: das hier ist gefährlicher unsinn
get_command()
{
	local _default_command='default'
	if [ $# -eq 0 ]; then
		printf '%s' ${_default_command}
	else
		printf '%s' ${1}
	fi
}

# map command to function
# NOTE: the whole point in naming is:  does naming reflect operations on trash
#       (and object names therein) or something else?
run_command()
{
	# NOTE: as for now we assume always a given command!
	# NOTE: should 'delete' be the term for final delete (from(!)) trash)?
	#     > likely yes!
 	local _command
 	local _command_default='put'
 	printf '$1: %s\n' $1
	case $1 in
		'put' | 'delete' | 'trash' | 'get' | 'undelete' | 'recover' | 'restore' | 'erase' | 'remove' | 'rm' | 'purge' | 'shred' | 'clear' | 'clean' | 'empty' | 'list' )
			printf 'using command: %s\n' $1
			_command=$1
			shift
		;;
		* )
			if [ -e "$1" ]; then
				printf 'using default command: %s\n' 'put'
				_command="$_command_default"
			else
				error_usage
			fi
		;;
	esac
 	case $_command in
		# NOTE: if 'undelete' is the way back from(!) trash, delete is 'put'
		# TODO: see the spec! to get this sorted
		#     > Trashing — a “delete” operation in which files are transferred into the Trash can
		put | trash | delete )
			printf 'running command: %s\n' 'put'
			trash_put "$@"
		;;
		# NOTE: german wording here (for undelete) is: "Wiederherstellen"
		get | undelete | recover )
			printf 'running command: %s\n' 'get'
			:
		;;
		list )
			printf 'running command: %s\n' 'list'
			trash_list "$@"
		;;
		# NOTE: in german language this operation is named 'Löschen' in file manager
		# SPEC: Erasing — an operation in which files (possibly already in the Trash can) are removed (unlinked) from the file system. An erased file is generally considered to be non-recoverable; the space used by this file is freed.
		erase | remove | rm )
			printf 'running command: %s\n' 'erase'
			trash_erase "$@"
		;;
		# SPEC: A “shredding” operation, physically overwriting the data, may or may not accompany an erasing operation; the question of shredding is beyond the scope of this document.
		# TODO: if we can, we might remove data bit by bit
		shred | purge )
			printf 'running command: %s\n' 'erase (shredding is not implemented yet)'
			trash_erase "$@"
		;;
		clear | clean )
			:
		;;
		* )
			error_internal 9
		;;
	esac
}

exit=0 # valid?
command=$(get_command $@)
if [ "$command" != "default" ]; then
	shift 1
fi
run_command $command $@

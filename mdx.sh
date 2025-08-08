#
# WARNING / NOTE
# the function herein defined must not run as a shell skript - it has to be used as a
# bash function! and should be "installed" via .bashrc
#
# mkdir extended (mdx)
# create a new directory and switch to it with an additional return or not with ... ESC
#
# TODO:
# add option --today
#
# TODO:
# ESC doable?
# https://superuser.com/questions/1267984/how-to-exit-read-bash-builtin-by-pressing-the-esc-key
#
# TODO:
# have an environmental default to **always** enter the new directory without
# any interaction such as MDX_CD=true|yes. this also might have a command line
# option such -c (cd!) or -y (--yes) this. we also want --no to override
# environmental default is set



function mdx ()
{
	local _me='mdx'

#  	invert() { return "$(( ! $1 ))"; }
#   	invert() { $1 ? return 'false' : return 'true'; }
#   	invert() { $1 ? printf 'false' : printf 'true' }
#  	invert() { local _ret; $1 ? _ret='false' : _ret='true'; printf '%s' $_ret; }
# 	invert() { local _ret; _ret=$(($1 ? 'false' : 'true')); printf '%s' $_ret; }
	invert() { $1 && printf '%s' 'false' || printf '%s' 'true'; }

	typeset -i _read_timeout=${MDX_TIMEOUT:-5}	# read command's timeout in seconds

	set -x
	local _do_cd=${MDX_CHANGE_DIR:-false}
#  	local _do_ask=$(invert $_do_cd)
# 	local _do_ask=$(( $_do_cd ? false : true )) # WARNING: seems odd :( subprocess?
#  	local _do_ask=${_do_cd:-true}
 	local _do_ask=$(invert $_do_cd)
	set +x
	local _mkdir_mode_flag=''
	local _mkdir_parent_flag=''
	local _mkdir_verbose_flag=''
	local _md_error=''	# mkdir(1)'s error message if some
	local _md_exit=0 	  # mkdir(1)'s exit status (code)

	function _usage ()
	{
		printf "\nusage: $_me [options] <new-directory>

    options:
      -n, --no          : do not change to new directory
      -c, --cd          : do change to new directory without prompt
      -y, --yes         : same as 'yes'

      -m, --mode=MODUS  : set file mode as umask (default 0777)
      -p, --parents     : do not complain about existing directories and create with all parent
      -t, --today       : evaluate environment variable \$TODAY and created a directory named of it
      -v, --verbose     : be verbose about any created directory

" >&2
		printf '\n'
	}

	# we check for options given first
	_options="$( getopt --alternative --options chm:nptvy --longoptions cd,help,mode,no,parents,today,verbose,yes --name "$0" -- "$@" )"
	eval set -- "${_options}"
	while true; do
		case "$1" in
			-c | --cd | -y | --yes )
				_do_cd=true
				_do_ask=false
				shift 1
			;;
			-h | --help )
				_usage
				return 0
			;;
			-m | --mode )
				_mkdir_mode_flag="--mode=$2"
				shift 2
			;;
			-n | --no )
				_do_cd=false
				_do_ask=false
				shift 1
			;;
			-p | --parents )
				_mkdir_parent_flag='--parents'
				shift 1
			;;
			-t | --today )
				if [[ -n "$TODAY" ]]; then
					set -- --today -- "$TODAY"
					shift 1
				else
					printf "\nEnvironment variable not set: '\$TODAY'\n" >&2
					return 1
				fi
			;;
			-v | --verbose )
				_mkdir_verbose_flag='--verbose'
				shift 1
			;;
			--)
				shift
				break
			;;
			*)
				printf "\nUnknown or not implemented yet option: '$1'\n" >&2
				__usage
				return 1
			;;
		esac
	done

	# run mkdir(1) with or without arguments (to get the native error message)
	if [[ $# > 0 && -n "$1" ]]; then
		_md_error="$(command mkdir $_mkdir_mode_flag $_mkdir_parent_flag $_mkdir_verbose_flag "$1" 2>&1)"; _md_exit=$?
	else
		_md_error="$(command mkdir 2>&1)"; _md_exit=$?
	fi

	# if mkdir(1) fails for any reason, we reuse it's error message and exit with it's exit status
# 	[[ $_md_exit != 0 ]] && printf '%s\n' "$_md_error" | sed "s/mkdir/$_me/g" && return $_md_exit
	test $_md_exit -ne 0 && printf '%s\n' "$_md_error" | sed "s/mkdir/$_me/g" && return $_md_exit # VALID?

	# ask user, if no option has been given
	echo $_do_ask
# 	return

	if $_do_ask; then
		read -t $_read_timeout -p "Change to new directory '${1}' now? [Y|n] "
		case "${REPLY}" in
			'' ) _do_cd=true; printf '\n' ;;
			[Yy]+ ) _do_cd=true ;;
			[Nn]+ ) _do_cd=false ;;
			* ) : ;;
		esac
	fi

	# if given by option or interactively change to new directory
# 	$_do_cd && printf '\n' && command cd "$1"
	$_do_cd && command cd "$1"
}

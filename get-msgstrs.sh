#! /usr/bin/env bash

# get-msgstrs.sh

# get and print templated translations for a specific string (<query>) inside <appid>

# to get the translation in a format suitable for a .desktop file a template is required:
# 'Name[%s]=%s\n'

_echo_exit ()
{
	printf '%s\n' "$*" >&2
	exit 1
}

test $# -ge 2 || _echo_exit "usage: $(basename $0) <appid> <query> [<template>]"

default_print_tmplt='%s %s\n'

appid="$1"
query="$2"
tmplt="${3:-$default_print_tmplt}"

# tranlations are in:
locale_base_dir="/usr/share/locale"

# get a list of all locales therein
_all_locales ()
{
	cd $locale_base_dir
	echo *
}

_main ()
{
#	# store all locales inside a simple indexed array
#	declare all_locales=( $(_all_locales) )
#	for locale in ${all_locales[*]}; do

	# or direct and without an array
	for locale in $(_all_locales); do

		mo="$locale_base_dir/$locale/LC_MESSAGES/${appid}.mo"
		if [[ -r "${mo}" ]]; then
		
			# this is what an (decompiled) german entry of e.g. 
			# dolphin Reload looks like and to grab strings from:
			
			# msgid "Reload"
			# msgstr "Aktualisieren"
			
			# get the line below the matching query
			msgstr_line=$(msgunfmt "${mo}" | grep -A1 "\"${query}\"" | tail -1)
			
			# trim by "msgstr" from left
			msgstr="${msgstr_line#"msgstr "}"
			
			# trim '"' left and right
			msgstr="${msgstr//\"}"
			
			# format output nicely
			printf "${tmplt}" "${locale}" "${msgstr}"
		else
			: # ignore that silently. there are just too many of these
		fi

	done
}

_main

#!/bin/bash

MY_PATH="${BASH_SOURCE[0]}"
MY_FILE="${MY_PATH##*/}"
MY_NAME="${MY_FILE%%.*}"
MY_CONF="${MY_NAME}.conf" # oder (more KDE Style): MY_CONFIG="${MY_NAME}rc   print-itrc sieht aber schräg aus
MY_CONF_FILE="$HOME/.config/${MY_CONF}"

kread_config_avails=( $(type -p kreadconfig kreadconfig6 kreadconfig5) )
KREAD_CONF_COMMAND=${kread_config_avails[0]}
# kdialog --msgbox "KREAD_CONF_COMMAND: $KREAD_CONF_COMMAND"

### configs we have
# notification_timeout_config_value=$($KREAD_CONF_COMMAND --file "$MY_CONF_FILE" --group 'Notification Messages' --key 'Timeout')
# NOTIFICATION_TIMEOUT=${notification_timeout_config_value:-2000}


### error_exit
### even more simple error handling
error_exit()
{
	local _error_str="$(gettext "ERROR")"
	local _error_msg="$1"
	local _error_num=${2:-1}
	$gui && kdialog --title 'Find Dups' --error "$_error_str: $_error_msg" --ok-label "So Sad"
	$cli && printf "\n$_error_str: $_error_msg\n\n" >&2
	exit $_error_num
}

### find my external required command
# WARNING fdupes seems not to be the righ thing. It only accepts directories as parameters
is_fdupes_available()
{
	type -p 'fdupes' > /dev/null 2>&1 || return 1
}

### find my external required command
# WARNING fdupes seems not to be the righ thing. It only accepts directories as parameters
is_rdfind_available()
{
	type -p 'rdfind' > /dev/null 2>&1 || return 1
}



# solo:find-dups$ ct results.txt
# # Automatically generated
# # duptype id depth size device inode priority name
# DUPTYPE_FIRST_OCCURRENCE 1 0 7 2065 166998583 1 FindMe
# DUPTYPE_OUTSIDE_TREE -1 1 7 2065 166998584 2 ./sample-dir/FindMe

### main function
main()
{
	if ! is_rdfind_available; then
		error_exit "Could not locate rdfind(1) command. You might have to install it first. I must quit"
	fi

	# TODO check params on existence
	search_in_dir="$1"
	duplicates_of="$2"

	# just some quick feedback to the user
 	echo -e "search in: $search_in_dir,\nfor dups of:  $duplicates_of\n..."
 	kdialog --title 'Find Dups' --msgbox "search in: $search_in_dir,\nfor dups of:  $duplicates_of\n..."

	result_dir="$(mktemp --directory -t find-dups.XXXXXXX)"
	result_txt="$result_dir/results.txt"

	### now find duplicates
	command rdfind -outputname /dev/stdout "$search_in_dir" "$duplicates_of" | tail -3 | head -2 >"$result_txt"

	#  TODO output on comamnd line or dialog - not both
	### in case we've been run on command line
	command cat "$result_txt" #| tail -3 | head -2
	kdialog --geometry 1000x100 --textbox "$result_txt" >/dev/null 2>&1 # geometry option creates a geometry line in stdout

	### delete or open found duplicate? or just OK!

	### clean up
	command rm "$result_txt"
	command rmdir "$result_dir"
}

# kdialog --title 'Find Dups' --msgbox "searching..."

main "$@"

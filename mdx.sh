#!/bin/bash
# mkdir extended (mdx)
# create a new directory and switch to it with a an additional return or not with ... ESC? (doable)
# https://superuser.com/questions/1267984/how-to-exit-read-bash-builtin-by-pressing-the-esc-key

# NOTE:
# there is no exit command used here, although it is tempting, to allow the use of this inside an alias file

timeout=2 # seconds

# define a function
function mdx()
{
	mkdir "$1"
	read -t $timeout -i 'Y' -p "Change to new directory: ${1}? [Y|n]"
	case "$REPLY" in
		[Yy] | '' ) cd "$1" ;;
		*) : ;;
	esac
}

# run this function
mdx

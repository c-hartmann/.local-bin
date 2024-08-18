what()
{
	command=$1
	test -n $command || return
	#  -t option reduces type(1) reply to a single words
	type=$(LANG=C type -t $command)
	if [ -n "$type" ]; then
		case $type in
			alias )
				# do not try to locate binary if alias is aliased to another alias
				LANG=C type -a $command | head -1
				# do we have a path to it?
				path=$(type -P $command)
				if [ -z $path ]; then
					# try recursion ...
					aliased_to=$(LANG=C type $command | head -1 | cut -d'`' -f2 | cut -d' ' -f1)
					what $aliased_to
				else
					type -aP $command
				fi
				;;
			builtin )
				type $command
				;;
			file )
				where=$(type -p $command)
				what="$(file $where)"
				printf '%s\n' "$what"
				;;
			function )
				type $command | head -1
				;;
			keyword )
				type $command
				;;
			* )
				# this might be a simple file
				unknown=$command
				where=$(locate $unknown)
				what="$(file $where)"
				printf '%s\n' "$what"
				;;
		esac
	else
		# this might be a variable
		if [ -v $command ]; then
			printf '%s\n' "'$command' is a variable and set to: \"$(eval printf '%s' \$$command)\""
		else
			printf '%s\n' "no idea what '$command' is"
		fi
	fi
}

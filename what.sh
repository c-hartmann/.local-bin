what () 
{ 
    command=$1;
    test -n $command || return;
    type=$(type -t $command);
    if [ -n "$type" ]; then
        case $type in 
            builtin)
                type $command
            ;;
            function)
                type $command
            ;;
            alias)
                type -a $command;
                where=$(LANG=C type -a $command | tail -1 | cut -d' ' -f3);
                what="$(file $where)";
                printf '%s\n' "$what"
            ;;
            keyword)
                type $command
            ;;
            file)
                where=$(type -p $command);
                what="$(file $where)";
                printf '%s\n' "$what"
            ;;
            *)
                unknown=$command;
                where=$(locate $unknown);
                what="$(file $where)";
                printf '%s\n' "$what"
            ;;
        esac;
    else
        printf '%s\n' "no idea what '$command' is";
    fi
}

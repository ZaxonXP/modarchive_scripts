#!/bin/bash
REQUEST=$1
ARTIST=$2
POSF=$3
PAGE=$4

###############################################################################
URL="http://modarchive.org/index.php?request=$REQUEST&query=$ARTIST"
###############################################################################
get_pos() {
    local data=$(cat $POSF)
    PAGE=${data%%:*}
    SONG=${data%:*}
    SONG=${SONG#*:}
    MAX=${data##*:}
}

###############################################################################
get_mod_and_play() {
    local urlloc=$1
    local file=${urlloc#*\#}

    wget -q -O $dir/$file "$urlloc"
    echo -e "$urlloc\n"
    (sleep 1; echo -n . > /tmp/openmpt123_fifo)&
    openmpt123 --no-meters --banner 0 --assume-terminal $dir/$file < /tmp/openmpt123_fifo
    rm $dir/$file
}

###############################################################################
get_mod_list() {
    local page=$1
    LIST=( "" $(lynx -dump -listonly -nonumbers "${URL}&page=${page}" | grep download | uniq) )
    MAX=$(( ${#LIST[*]} - 1 ))
}

###############################################################################
ask_for_rewind() {
    read -n 1 -p "End of playlist. Rewind? [Y/n] " answ
    case $answ in
        [yY])
            SONG=0
            PAGE=0
            ;;
        [nN])
            exit 0
            ;;
    esac
}

###############################################################################
cleanup() {
    rm -rf $dir
    rm /tmp/openmpt123_fifo
    rm /tmp/openmpt123_list
    reset
    exit 0;
}

######################## Main code ############################################
[ -z "$PAGE" ] && [ ! -f $POSF ] && PAGE=1 && SONG=1
[ -z "$PAGE" ] && [   -f $POSF ] && get_pos

dir=$(mktemp -p /tmp -d)

[ ! -p /tmp/openmpt123_fifo ] && mkfifo /tmp/openmpt123_fifo
[ ! -f /tmp/openmpt123_list ] && echo $POSF > /tmp/openmpt123_list

trap 'cleanup' SIGINT

while [ 1 ]; do
    get_mod_list $PAGE
    while [ $SONG -le $MAX ]; do
        clear
        echo -n "[$PAGE:$SONG:$MAX] "
        echo "$PAGE:$SONG:$MAX" > $POSF
        get_mod_and_play ${LIST[$SONG]}
        get_pos
        ((SONG+=1))
    done
    [ $SONG -gt $MAX ] && [ $MAX -lt 40 ] && ask_for_rewind
    SONG=1
    ((PAGE+=1))
done

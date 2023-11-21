#!/bin/bash
DEBUG=
CONF=$XDG_CONFIG_HOME/modarchive_play_from_web/modarchive.conf
SKIPFAV=$(grep -c SKIPFAV $CONF)
SKIPREJ=$(grep -c SKIPREJ $CONF)
ALWAYS_REWIND=$(grep -c ALWAYS_REWIND $CONF)
statfile=/tmp/module_fav_stat
fifo=/tmp/openmpt123_fifo
list=/tmp/openmpt123_list
cfile=/tmp/openmpt123_conf

echo $CONF > $cfile

###############################################################################
get_pos() {
    local data
    data=$(cat "$POSF")
    PAGE=${data%%:*}
    SONG=${data%:*}
    SONG=${SONG#*:}
    MAX=${data##*:}
    [ $DEBUG ] && echo "P: [$PAGE:$SONG:$MAX]"
}

###############################################################################
check_my_favourities() {
    local url=$1

    if [ "$(grep -c "$url" "$FAVFILE")" == "1" ]; then
        echo "+"
        echo "+" > $statfile
    elif [ "$(grep -c "$url" "$REJFILE")" == "1" ]; then 
        echo "x"
        echo "x" > $statfile
    else
        echo "-"
        echo "-" > $statfile
    fi
}

###############################################################################
check_fav_list() {
    local urlloc
    local stat1
    urlloc=$1

    stat1=$(grep -c "$urlloc" "$FAVFILE")
    [ "$stat1" -eq 1 ] && echo "1" || echo "0"
}

###############################################################################
check_reject_list() {
    local urlloc
    local stat2
    urlloc=$1

    stat2=$(grep -c "$urlloc" "$REJFILE")
    [ "$stat2" -eq 1 ] && echo "1" || echo "0"
}

###############################################################################
check_lists() {
    local STAT1
    local STAT2
    local STAT
    local SURL
    SURL=$1
    STAT=0
    
    # check if module is in FAV or REJ file
    SFAV="$(check_fav_list "$SURL" )"
    SREJ="$(check_reject_list "$SURL")"

    #echo "P:$PAGE,S:$SONG,SF:$SKIPFAV,CF:$SFAV,SR:$SKIPREJ,CR:$SREJ" >> ~/stat

    # If SKIPFAV = 1 and module is found on FAV list, then do not play current
    [ "$SKIPFAV" == "1" ] && [ "$SFAV" == "1" ] && echo 0 && return
    # If SKIPREJ = 1 and module is found on REV list, then do not play current
    [ "$SKIPREJ" == "1" ] && [ "$SREJ" == "1" ] && echo 0 && return
    # If STAT1 and STAT2 are 0 then it is normal list, so play it
    [ "$SKIPFAV" == "1" ] && [ "$SFAV" == "0" ] && STAT1=1
    [ "$SKIPREJ" == "1" ] && [ "$SREJ" == "0" ] && STAT2=1
    [ "$STAT1" == "1" ] && [ "$STAT2" == "1" ] && echo 1 && return 0
    # If SKIPFAV = 0 and module and module found on FAV list, then play it
    [ "$SKIPFAV" == "0" ] && echo 1 && return 0
    # If SKIPREJ = 0 and module and module found on REJ list, then play it
    [ "$SKIPREJ" == "0" ] && echo 1 && return 0
    # default is not to play this module
    echo 0
}
###############################################################################
get_mod_and_play() {
    local title=$1
    local urlloc=$2
    local file=${urlloc#*\#}
    clear
    echo "$title"
    check_connection
    favstat=$(check_my_favourities "$urlloc") 
    wget -O "$dir/$file" "$urlloc"
    clear
    echo "$title"
    echo -e "$favstat $urlloc\n"
    (sleep 1; echo -n . > $fifo)&
    openmpt123 --no-meters --banner 0 --assume-terminal "$dir/$file" < "$fifo"
    rm "$dir/$file"
}

###############################################################################
check_connection() {
    while true; do 
        check=$(ping -c 2 $SITE 2> /dev/null | grep -c "2 received")
        [ "$check" -eq 1 ] && break 
        [ "$check" -ne 1 ] && restart_net.sh && sleep 5
        sleep 1
    done
}
###############################################################################
get_mod_list() {
    local page=$1
    local last=$2
    check_connection
    echo -ne "\r Getting list $page of $last  "
    mapfile -t -O 1 LIST < <(lynx -dump -listonly -nonumbers "${URL}&page=${page}" 2> /dev/null | grep download | uniq)
    LIST[0]=""
    MAX=$(( ${#LIST[*]} - 1 ))
}

###############################################################################
get_last_page_number() {
    check_connection
    LAST=$(lynx -dump -listonly -nonumbers "${URL}&page=${page}" 2> /dev/null | grep "#mods" | tail -1)
    LAST=${LAST//#*}
    LAST=${LAST##*=}
    echo "$LAST"
}

###############################################################################
get_mod_list_local() {
    local ppage
    local ffile
    ppage=$1
    [ "$TYPE" == "NORMAL" ] && ffile=$(printf "%s/page_%04d.txt" "$conf" "$ppage")
    [ "$TYPE" == "FAV"    ] && ffile=$FAVFILE
    [ "$TYPE" == "REJ"    ] && ffile=$REJFILE

    [ $DEBUG ] && echo "FFILE = $ffile"; read

    mapfile -t -O 1 LIST < <(cat "$ffile")
    LIST[0]=""
    MAX=$(( ${#LIST[*]} - 1 ))
}

###############################################################################
ask_for_rewind() {
    read -r -n 1 -p "End of playlist. Rewind? [y/n] " answ
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
check_for_local_lists() {
    local locdir=$1
    local pos=$2

    if [ ! -f "$pos" ]; then

        cd "$locdir" || exit 1
        local page=0
        LAST=$(get_last_page_number)

        while true; do
            ((page++))
            get_mod_list "$page" "$LAST"
            pfile=$(printf "page_%04d.txt" $page)

            for (( i=1; i<=MAX; i++ )); do
                [ $i -eq 1 ] && echo "${LIST[$i]}" > "$pfile" || echo "${LIST[$i]}" >> "$pfile"
            done

            [ $MAX -lt 40 ] && break
        done
        MAX=$(wc -l < page_0001.txt)
        echo "1:1:$MAX" > "$pos"
    else
        echo "Pos file exists"
    fi
}
###############################################################################
get_list_only() {
    local DIR=$1

    [ ! -d "$DIR" ] && mkdir "$DIR" 
    
    check_for_local_lists "$DIR" "pos.last"
    exit 0
}

###############################################################################
cleanup() {
    rm -rf "$dir"
    rm "$fifo"
    rm "$list"
    rm "$statfile"
    rm "$cfile" 
    reset
    exit 0;
}

####################### Config section ########################################
if [ "$1" != "-g" ]; then
    REQUEST=$1
    ARTIST=$2
    POSF=$3
    PAGE=$4

    conf=$XDG_CONFIG_HOME/$(basename "$0")
    conf=${conf/.sh/}
    [ ! -d "$conf" ] && mkdir "$conf"
    conf="$conf/$POSF"
    [ ! -d "$conf" ] && echo "Directory \"$conf\" does not exit" && exit 2
    NAME="$POSF"
    POSF="${conf}/pos.last"
    FAVFILE="${conf}/fav.txt"
    REJFILE="${conf}/rej.txt"

    # check if user wants to play FAV/REJ/NORMAL playlist
    msg="Normal"
    [ -f $FAVFILE ] && msg="$msg\nFavorites"
    [ -f $REJFILE ] && msg="$msg\nRejected"

    ans=$(echo -e $msg | fzf);

    [ "$ans" == "" ] && exit 0

    TYPE=NORMAL
    [ "$ans" = "Favorites" ] && TYPE=FAV && SKIPFAV=0 && POSF=${POSF/pos/fav}
    [ "$ans" = "Rejected"  ] && TYPE=REJ && SKIPREJ=0 && POSF=${POSF/pos/rej}

    [ $DEBUG ] && echo "REQUEST = $REQUEST"
    [ $DEBUG ] && echo "ARTIST  = $ARTIST"
    [ $DEBUG ] && echo "POSF    = $POSF"
    [ $DEBUG ] && echo "conf    = $conf"
    [ $DEBUG ] && echo "FAVFILE = $FAVFILE"
    [ $DEBUG ] && echo "REJFILE = $REJFILE"
    [ $DEBUG ] && echo "SKIPFAV = $SKIPFAV"
    [ $DEBUG ] && echo "SKIPREJ = $SKIPREJ"
    [ $DEBUG ] && echo "$NAME" 
    [ $DEBUG ] && read
else
    REQUEST=$2
    ARTIST=$3
    DIR=$4 
fi

###############################################################################
SITE=modarchive.org
URL="http://$SITE/index.php?request=$REQUEST&query=$ARTIST"

######################## Main code ############################################
[[ "$1" == "-g" ]] && get_list_only "$DIR"

unset PS1

[ -z "$PAGE" ] && [ ! -f "$POSF" ] && PAGE=1 && SONG=1
[ -z "$PAGE" ] && [   -f "$POSF" ] && get_pos
[ "$ALWAYS_REWIND" == "1" ] && PAGE=1 && SONG=1

dir=$(mktemp -p /tmp -d)

[ ! -p "$fifo" ] && mkfifo "$fifo"
[ ! -f "$list" ] && echo "$POSF" > "$list"

trap 'cleanup' SIGINT

check_for_local_lists "$conf" "$POSF"

while true; do
    get_mod_list_local "$PAGE"
    while [ "$SONG" -le "$MAX" ]; do
        clear
        echo "N: [$PAGE:$SONG:$MAX]"
        echo "$PAGE:$SONG:$MAX" > "$POSF"
        get_mod_list_local "$PAGE"
        CURSONG=${LIST[$SONG]}
        [ "$(check_lists "$CURSONG")" == "1" ] && get_mod_and_play "[$PAGE:$SONG:$MAX] $NAME" "$CURSONG"
        get_pos
        ((SONG+=1))
    done
    [ "$SONG" -gt "$MAX" ] && [ "$MAX" -lt 40 ] && ask_for_rewind
    SONG=1
    ((PAGE+=1))
done

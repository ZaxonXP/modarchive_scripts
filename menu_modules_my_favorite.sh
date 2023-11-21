#!/bin/bash
# Add currently played module to my favorite list
#export PS1="$ "

#############################################################################################
TMPLIST="/tmp/openmpt123_list"
STATFILE="/tmp/module_fav_stat"
TIMEOUT=2000

#############################################################################################
get_data() {
    local list pos PAGE SONG path file select stat stat2
    list=$(cat "$TMPLIST")
    pos=$(cat "$list")

    PAGE=${pos%%:*}
    SONG=${pos%:*}
    SONG=${SONG#*:}

    path=${list%/*}

    file=$(printf "%s/page_%04d.txt" "$path" "$PAGE")
    select=$(head -"$SONG" "$file" | tail -1) 

    echo "$select"
}

#############################################################################################
add_to_fav() {
    local data PAGE SONG select stat
    select=$1

    # make fav file if it does not exist
    if [ ! -f "$FAVFILE" ]; then
        touch "$FAVFILE"
        stat=0
    else
        stat=$(grep -c "$select" "$FAVFILE")
    fi

    [ "$stat"  != "0" ] && notify-send -a MOD -u normal -t $TIMEOUT "Add module" "Module already on the list" && echo "+" > $STATFILE && return 1

    if [ -f "$FAVLAST" ]; then
        data=$(cat "$FAVLAST")
        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
    else
        PAGE=1
        SONG=1
    fi

    echo "$select" >> "$FAVFILE"
    echo "+" > $STATFILE
    last=$(wc -l "$FAVFILE" | cut -d" " -f1)
    echo "$PAGE:$SONG:$last" > "$FAVLAST"

    # remove from rej file if the entry was already there
    if [ -f "$REJFILE" ]; then
        data=$(cat "$REJLAST")
        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
        if [ "$(grep -c "$select" "$REJFILE")" != "0" ]; then
            line=$(grep -n "$select" "$REJFILE")
            line=${line%%:*}
            sed -i "${line}d" "$REJFILE"
            last=$(wc -l "$REJFILE" | cut -d" " -f1)
            echo "$PAGE:$SONG:$last" > "$REJLAST"
        fi
    fi
    notify-send -a MOD -u normal -t $TIMEOUT "Add module" "Module added"
}

#############################################################################################
add_to_rej() {
    local stat2 data PAGE SONG last select
    select=$1

    # make reject file if it does not exist
    if [ ! -f "$REJFILE" ]; then
        touch "$REJFILE"
        stat2=0
    else
        stat2=$(grep -c "$select" "$REJFILE")
    fi

    [ "$stat2" != "0" ] && notify-send -a MOD -u normal -t $TIMEOUT "Add module" "Module already on the reject list" && echo "x" > $STATFILE && return 1

    if [ -f "$REJLAST" ]; then
        data=$(cat "$REJLAST")
        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
    else
        PAGE=1
        SONG=1
    fi

    echo "$select" >> "$REJFILE"
    echo "x" > $STATFILE
    last=$(wc -l "$REJFILE" | cut -d" " -f1)
    echo "$PAGE:$SONG:$last" > "$REJLAST"

    # remove from fav file if the entry was already there
    if [ -f "$FAVFILE" ]; then
        data=$(cat "$FAVLAST")
        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
        if [ "$(grep -c "$select" "$FAVFILE")" != "0" ]; then
            line=$(grep -n "$select" "$FAVFILE")
            line=${line%%:*}
            sed -i "${line}d" "$FAVFILE"
            last=$(wc -l "$FAVFILE" | cut -d" " -f1)
            echo "$PAGE:$SONG:$last" > "$FAVLAST"
        fi
    fi
    notify-send -a MOD -u normal -t $TIMEOUT "Add module" "Module added to reject file"
}

#############################################################################################
get_cur_dir() {
    local curdir
    local TMPLIST
    TMPLIST=$1

    curdir="$(cat "$TMPLIST")"
    curdir=${curdir%/*}

    echo "$curdir"
}

#############################################################################################
interactive() {
    local title sel name con
    title="Add current module to fav/rej file? [f/r] " 
    tconf=">>> Add file \"$sel\" to \"$type\" list? [y/n] " ans

    while true; do
        clear
        read -N 1 -p "$title" answ
        echo ""
        sel=$(get_data)
        name=${sel#*\#}

        case $answ in
            [fF])
                type=fav
                read -N 1 -p ">>> Add file \"$name\" to \"$type\" list? [y/n] " con
                [ "$con" == "y" ] && add_to_fav "$sel"
                ;;
            [rR])
                type=rej
                read -N 1 -p ">>> Add file \"$name\" to \"$type\" list? [y/n] " con
                [ "$con" == "y" ] && add_to_rej "$sel"
                ;;
        esac
    done
}

#############################################################################################
menu() {
    local title answ sel
    title="Add current module to favorites or Blacklist?"
    answ=$(echo -e "Add\nBlacklist" | dmenu -i -fn "monospace:size=13" -p "$title: " -nb "#8550eb" -nf yellow)
    answ=${answ,,}

    [ -z "$answ" ] && [ "$answ" != "add" ] && [ "$answ" != "blacklist" ] && exit 0
    
    sel=$(get_data)
    [ "$answ" == "add"       ] && add_to_fav "$sel"
    [ "$answ" == "blacklist" ] && add_to_rej "$sel"
}

#############################################################################################
# Auto configure items
if [ "$1" == "-i" ]; then
    while true; do
        [ -f "$TMPLIST" ] && break
    done
else
    [ ! -f "$TMPLIST" ] && exit 1
fi
cdir=$(get_cur_dir $TMPLIST) 
FAVFILE="$cdir/fav.txt"
REJFILE="$cdir/rej.txt"
FAVLAST="$cdir/fav.last"
REJLAST="$cdir/rej.last"

#############################################################################################
# Check file existence
[ ! -f "$STATFILE" ] && exit 1
[ ! -f "$TMPLIST" ] && notify-send -a MOD -A info -u critical "Add module" "OpenMTP list is not found" && exit 1

#############################################################################################
sel=$(get_data)
[ "$1" == "add" ] && add_to_fav "$sel"
[ "$1" == "rej" ] && add_to_rej "$sel"
[ "$1" == "-i" ]  && interactive
[ "$1" == "" ]    && menu

#!/bin/sh
# Controls OpenMPT123 using FIFO and media keys for
# play/pause/next/previous
DEBUG=

CONF=$(cat /tmp/openmpt123_conf)

[ "$(pidof openmpt123)" = "" ] && exit 0
command=$1

previous() {

    # control the playback of certain module list
    if [ -f /tmp/openmpt123_list ]; then

        pfile=$(cat /tmp/openmpt123_list)
        type=${pfile##*/}
        data=$(cat $pfile)

        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
        MAX=${data##*:}

        sfav=$(grep -c "SKIPFAV" $CONF)
        srej=$(grep -c "SKIPREJ" $CONF)

        [ $DEBUG ] && echo "SFAV: $sfav"
        [ $DEBUG ] && echo "SREJ: $srej"

        fav_file="${pfile%$type}fav.txt"
        rej_file="${pfile%$type}rej.txt"

        [ $DEBUG ] && echo "FAV FILE: $fav_file"
        [ $DEBUG ] && echo "REJ FILE: $rej_file"

        [ $sfav -eq 1 ] && search=1
        [ $srej -eq 1 ] && search=1
        [ "$type" = "fav.last" ] && search=2
        [ "$type" = "rej.last" ] && search=2

        [ $DEBUG ] && echo "SEARCH: $search"

        if [ "$search" = "1" ]; then

            while [ true ]; do

                [ $DEBUG ] && echo "P:S = $PAGE:$SONG"
                [ $SONG -eq 1 ] && PAGE=$(( $PAGE - 1 )) && SONG=$(( $MAX - 1 )) || SONG=$(( $SONG - 1 ))
                [ $DEBUG ] && echo "P:S = $PAGE:$SONG"

                list_file="$(printf "%spage_%04d.txt" ${pfile%pos.last} $PAGE)"
                prev_song=$(head -n $SONG $list_file | tail -1)
                match_fav=$(grep -c $prev_song $fav_file)
                match_rej=$(grep -c $prev_song $rej_file)

                [ $DEBUG ] && echo "PFILE    : $pfile"
                [ $DEBUG ] && echo "LIST FILE: $list_file"
                [ $DEBUG ] && echo "PREV SONG: $prev_song"
                [ $DEBUG ] && echo "MATCH FAV: $match_fav"
                [ $DEBUG ] && echo "MATCH REJ: $match_rej"


                [ $sfav -eq 1 ] && [ $match_fav -eq 0 ] && cfav=0 || cfav=1
                [ $srej -eq 1 ] && [ $match_rej -eq 0 ] && crej=0 || crej=1

                [ $DEBUG ] && echo "CFAV: $cfav"
                [ $DEBUG ] && echo "CREJ: $crej"
                [ $DEBUG ] && read -p "Wait" aaa

                if [ $cfav -eq 0 ] && [ $crej -eq 0 ]; then
                    
                    [ $SONG -eq 1 ] && PAGE=$(( $PAGE - 1 )) && SONG=$(( $MAX - 1 )) || SONG=$(( $SONG - 1 ))
                    [ $DEBUG ] && echo "[$PAGE:$SONG:$MAX]"
                    echo "$PAGE:$SONG:$MAX" > $pfile
                    break
                fi
            done

        elif [ $search -eq 2 ]; then 
            [ $SONG -eq 1 ] && PAGE=$(( $PAGE - 1 )) && SONG=$(( $MAX - 2 )) || SONG=$(( $SONG - 2 ))
            [ $DEBUG ] && echo "[$PAGE:$SONG:$MAX]"
            echo "$PAGE:$SONG:$MAX" > $pfile
        else
            [ $SONG -eq 1 ] && PAGE=$(( $PAGE - 1 )) && SONG=$(( $MAX - 1 )) || SONG=$(( $SONG - 1 ))
            [ $DEBUG ] && echo "[$PAGE:$SONG:$MAX]"
            echo "$PAGE:$SONG:$MAX" > $pfile
        fi

        echo -n q > /tmp/openmpt123_fifo

    else
        echo -n n > /tmp/openmpt123_fifo
    fi
}


[ "$command" = "next" ] && echo -n q > /tmp/openmpt123_fifo
[ "$command" = "" ]     && echo -n " " > /tmp/openmpt123_fifo
[ "$command" = "previous" ] && previous

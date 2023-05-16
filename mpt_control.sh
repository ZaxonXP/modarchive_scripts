#!/bin/sh
# Controls OpenMPT123 using FIFO and media keys for play/pause/next

[ "$(pidof openmpt123)" = "" ] && exit 0
command=$1

previous() {

    # control the playback of certain module list
    if [ -f /tmp/openmpt123_list ]; then
        pfile=$(cat /tmp/openmpt123_list)
        data=$(cat $pfile)

        PAGE=${data%%:*}
        SONG=${data%:*}
        SONG=${SONG#*:}
        MAX=${data##*:}

        if [ $SONG -eq 1 ]; then
            PAGE=$(( $PAGE - 1 ))
            SONG=$(( $MAX - 1 ))
        else
            SONG=$(( $SONG - 2 ))
        fi
        echo "[$PAGE:$SONG:$MAX]"
        echo "$PAGE:$SONG:$MAX" > $pfile
        echo -n q > /tmp/openmpt123_fifo

    else
        echo -n n > /tmp/openmpt123_fifo
    fi
}


[ "$command" = "next" ] && echo -n q > /tmp/openmpt123_fifo
[ "$command" = "" ]     && echo -n " " > /tmp/openmpt123_fifo
[ "$command" = "previous" ] && previous

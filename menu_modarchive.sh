#!/bin/bash
n=1  qu[$n]=00000;      req[$n]="view_top_favourites";     lab[$n]="_Top favourites"
n=2  qu[$n]="featured"; req[$n]="view_chart"         ;     lab[$n]="_All Featured Modules"
n=3  qu[$n]="tophits";  req[$n]="view_chart"         ;     lab[$n]="_The Most Downloaded"
n=4  qu[$n]=10;         req[$n]="view_by_rating_comments"; lab[$n]="_Rating_10"
n=5  qu[$n]=80387;      req[$n]="view_artist_modules";     lab[$n]="Ctrix"
n=6  qu[$n]=69185;      req[$n]="view_artist_modules";     lab[$n]="Purple Motion"
n=7  qu[$n]=69569;      req[$n]="view_artist_modules";     lab[$n]="Jogeir Liljedahl"
n=8  qu[$n]=69572;      req[$n]="view_artist_modules";     lab[$n]="Skaven252"
n=9  qu[$n]=69271;      req[$n]="view_artist_modules";     lab[$n]="Necros"
n=10 qu[$n]=69553;      req[$n]="view_artist_modules";     lab[$n]="Awesome"
n=11 qu[$n]=69008;      req[$n]="view_artist_modules";     lab[$n]="xtd"
n=12 qu[$n]=69004;      req[$n]="view_artist_modules";     lab[$n]="Elwood"
n=13 qu[$n]=92000;      req[$n]="view_artist_modules";     lab[$n]="Atekuro"

#################################################
get_posfile() {
    local label=$1
    local posfile=${label// /_}
    posfile=${posfile,,}
    posfile="$(dirname $0)/modarchive_${posfile}.last"
    echo $posfile
}
#################################################
IFS=$'\n'
sel=$(for (( i=1; i <= $(( ${#lab[*]} + 1 )); i++ )); do
    [ -n "${lab[$i]}" ] && echo "$i - ${lab[$i]}"
done | fzf --reverse --height=100 | awk '{print $1}')

posfile=$( get_posfile ${lab[$sel]} )
request=${req[$sel]}
artist=${qu[$sel]}

[ -n "$sel" ] && modarchive_play_from_web.sh $request $artist $posfile

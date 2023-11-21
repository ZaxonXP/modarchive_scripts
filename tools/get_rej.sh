#!/bin/sh
clear
../get_stat.pl $1 \x |highlight -O xterm256 --syntax=sh 

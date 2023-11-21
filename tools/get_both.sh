#!/bin/sh
clear
../get_stat.pl $1 b |highlight -O xterm256 --syntax=sh 

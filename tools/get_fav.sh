#!/bin/sh
clear
../get_stat.pl $1 + |highlight -O xterm256 --syntax=sh 

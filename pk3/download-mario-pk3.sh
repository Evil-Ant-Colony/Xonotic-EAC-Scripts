#!/bin/bash

readme=https://raw.github.com/MarioSMB/esk-modpack/master/README.md
dirs="ftp xonotic-data"
files=$(wget -q -O - $readme | grep -oE "http[^ ]+\.pk3" | grep -vE "quickmenu|hats")

for f in $files
do
	file_name=$(basename $f)
	echo -e "\e[31m$file_name\e[0m"
	for d in $dirs
	do
		wget -O $d/$file_name $f
	done
done


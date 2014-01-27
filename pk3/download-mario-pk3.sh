#!/bin/bash

readme=https://raw.github.com/MarioSMB/esk-modpack/master/README.md
dirs="ftp xonotic-data"
files=$(wget -q -O - $readme | grep -oE "http[^ ]+\.pk3" | grep -vE "quickmenu|hats")

for f in $files
do
	file_name=$(basename $f)
	echo -e "\e[32m$file_name\e[0m"
	for d in $dirs
	do
		if [ ! -f $d/$file_name ]
		then
			wget -O $d/$file_name $f
		else
			echo -e "\t $d/$file_name already here"
		fi
	done
done


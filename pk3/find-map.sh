#!/bin/bash

SEARCH_DIR=~/.xonotic/data

SELFDIR=$(dirname $(readlink -se "${BASH_SOURCE[0]}"))
source $SELFDIR/pk3-utils-source.sh

# list all the pk3 to be searched
function list_pk3()
{
	ls $SEARCH_DIR/*.pk3
}

# Search for a match in the pk3 name
function search_pk3_name()
{
	list_pk3 | grep $1
}

# Search for a match in all the pk3 contents
function search_pk3_contents()
{
	for pk3 in $(list_pk3)
	do
		if pk3_files $pk3 | grep -q "maps/.*$1.*\.bsp"
		then
			echo $pk3
		fi
	done
}

# Search first in pk3 names, then (if nothing maches) in pk3 contents
function search_pk3_fallback()
{
	found=$(search_pk3_name $1)
	if [ -z "$found" ]
	then
		search_pk3_contents $1
	else
		echo $found
	fi
}

function show_help()
{
	echo -e "\e[1mNAME\e[0m"
	echo -e "\t$0 - Search maps"
	echo
	echo -e "\e[1mSYNOPSIS\e[0m"
	echo -e "\t\e[1m$0\e[0m [\e[4moptions\e[0m...] \e[4mterm\e[0m..."
	echo -e "\t\e[1m$0\e[0m \e[1mhelp\e[0m|\e[1m-h\e[0m|\e[1m--help\e[0m"
	echo
	echo -e "\e[1mOPTIONS\e[0m"
	echo -e "\e[1m--search-mode=\e[22;4mmode\e[0m"
	echo -e "\tHow to search for a match. Possible values:"
	echo -e "\t *:\e[1mname\e[0m:Only search pk3 file names
\t *:\e[1mcontents\e[0m:Search for a bsp inside the pk3
\t *:\e[1mboth\e[0m:Search in the file names, if this fails, in the contents" | column -t -c 3 -s ":"
	echo
}

search_inside=""
search_function=search_pk3_fallback
out_function=echo

for arg in $@
do
	case $arg in
		
		help|--help|-h)
			show_help
			;;
		--search-mode=*)
			case ${arg#*=} in
				name)
					search_function=search_pk3_name
					;;
				contents)
					search_function=search_pk3_contents
					;;
				both)
					search_function=search_pk3_fallback
					;;
# 				*)
# 					echo "Unknown search mode: ${arg#*=}"
# 					;;
			esac
			;;
		*)
			$out_function $($search_function $arg)
			;;
	esac
done
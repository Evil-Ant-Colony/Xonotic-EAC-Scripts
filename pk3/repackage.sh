#!/bin/bash
#set -x

Q3MAP2=q3map2
Q3MAP2_FLAGS=
FIX_DIR=~/repackaged

source $(dirname $(readlink -se "${BASH_SOURCE[0]}"))/pk3-utils-source.sh

# @brief check whether a pk3 contains all needed files for the given map
# @pre the pk3 contains maps/$2.bsp
# @param $1 pk3 name
# @param $2 map name
function pk3_check_map()
{
	declare -i issues
	
	if ! pk3_contains $1 "maps/$2\.(jpg|jpeg|tga|png)"
	then
		if pk3_contains $1 "levelshots/$2\.(jpg|jpeg|tga|png)" 
		then
			echo $2: Wrong preview image
			let issues++
		else
			echo "$2: Missing preview image (not fixable)"
		fi
	fi
	
	if ! pk3_contains $1 "gfx/$2_mini\.tga" 
	then
		echo $2: Missing minimap
		let issues++
	fi
	
# 	if ! pk3_contains $1 "maps/$2\.mapinfo" 
# 	then
# 		echo $2: Missing mapinfo
# 		let issues++
# 	fi
	
	return $issues
}

# @brief print colored text
# @param $1 ANSI style (eg: 31 for red text)
# @param $2... text to write
function echo_color()
{
	text=`echo $* | sed -r "s/^[0-9]+(;[0-9]+)* //"`
	echo -e "\e[$1m$text\e[0m"
}

# @brief check if a package needs (and can be) fixed
function pk3_check()
{
	echo Checking $1...
	
	if ! pk3_is_map $1
	then
		echo_color 32 $1 is not a map pk3
		return 0
	fi
	
	declare -i issues
	let issues=0
	
	maps=$(pk3_maps $1)
	
	if pk3_contains $1 "[^/]+\.dat"
	then
		echo $1: Contains dat files
		let issues++
	fi
	
	if pk3_contains $1 "effectinfo\.txt"
	then
		echo $1: Contains effectinfo
		let issues++
	fi
	
	if pk3_contains $1 ".+\.serverpackage"
	then
		echo $1: Contains serverpackage
		let issues++
	fi
	
	for map in $maps
	do
		map=`basename $map .bsp`
		pk3_check_map $1 $map
		let issues+=$?
	done
	
	if [ $issues -ne 0 ]
	then
		echo -e "\e[33;1m$1\e[22m has $issues fixable issues\e[0m"
	else
		echo -e "\e[32;1m$1\e[22m is fine\e[0m"
	fi
	
	return $issues
}

# @brief print the file name of the package output by pk3_fix
# @param $1 pk3 name
function pk3_fix_name()
{
	echo $FIX_DIR/`basename $1 .pk3`$RENAME_SUFFIX.pk3
}

# @brief extract the pk3 and fixes any issues
# @param $1 pk3 name
function pk3_fix()
{
	echo_color 36 Fixing $1
	package=`basename $1 .pk3`
	mkdir -p $FIX_DIR/$package
	unzip -u -d $FIX_DIR/$package $1 >/dev/null
	cwd=`pwd`
	cd $FIX_DIR/$package
	
	if [ ! -d gfx ]
	then
		mkdir gfx
	fi
	
	echo "Adding files"
	
	maps=`ls maps/*.bsp`
	for map in $maps
	do
		map_name=`basename $map .bsp`
		if [ ! -f "gfx/${map_name}_mini.tga" ]
		then
			$Q3MAP2 $Q3MAP2_FLAGS -minimap -o gfx/${map_name}_mini.tga $map >/dev/null
		fi
		
		if ! ( ls maps | grep -Eq "$map_name\.(jpg|jpeg|png|tga)" )
		then
			replacement=`ls levelshots | grep -E "$map_name\.(jpg|jpeg|png|tga)"`
			if [ -n "$replacement" ]
			then
				mv levelshots/$replacement maps
			fi
		fi
		
		if [ ! -f maps/$map_name.mapinfo ]
		then
			create_mapinfo maps $map_name 7
		fi
		
		if [ -n "$RENAME_SUFFIX" ]
		then
			echo "Renaming $map_name"
			for map_file in `find gfx maps -type f -name "*$map_name*"`
			do
				mv -T $map_file `echo $map_file | sed -r "s/$map_name(\.|_mini)/$map_name$RENAME_SUFFIX\1/"`
			done
		fi
	done
	
	echo "Cleaning up"
	
	rm -f *.dat effectinfo.txt maps/*_effectinfo.txt *.serverpackage
	
	if [ -d levelshots ]
	then
		rmdir --ignore-fail-on-non-empty levelshots 
	fi
	
	echo "Packaging"

	new_package=$package$RENAME_SUFFIX.pk3
	rm -f ../$new_package
	zip -p ../$new_package -r * >/dev/null
	
	echo Created $FIX_DIR/$new_package
	
	cd $cwd
}

function show_help()
{
	#Pseudo-man :-P
	echo_color 1 NAME
	echo -e "\t$0 - Check and convert pk3 files"
	echo
	echo_color 1 SYNOPSIS
	echo -e "\t\e[1m$0\e[0m \e[1mjust-check\e[0m \e[4mfile\e[0m"
	echo -e "\t\e[1m$0\e[0m [\e[1mcheck\e[0m|\e[1mfix\e[0m|\e[1mname\e[0m|\e[4moption\e[0m..] \e[4mfile\e[0m..."
	echo -e "\t\e[1m$0\e[0m \e[1mhelp\e[0m|\e[1m-h\e[0m|\e[1m--help\e[0m"
	echo
	echo_color 1 DESCRIPTION
	echo -e "\t\e[1m$0\e[0m performs the following checks:"
	echo -e "\t * Minimap"
	echo -e "\t * Mapinfo"
	echo -e "\t * Map preview"
	echo -e "\t * Files that can mess up config (effectinfo.txt *.dat)"
	echo -e "\tWill do nothing if the pk3 does not contain maps/*.bsp"
	echo -e "\totherwise it will add the needed files and remove the extra ones"
	echo
	echo_color 1 OPTIONS
	echo
	echo_color 1 "\tActions"
	echo -e "\t\t\e[1mjust-check\e[0m"
	echo -e "\t\t\tOnly perform checks on a single pk3"
	echo -e "\t\t\treturn 0 on success and 1 on failure"
	echo -e "\t\t\e[1mcheck\e[0m"
	echo -e "\t\t\tOnly perform checks and print issues with the pk3s"
	echo -e "\t\t\e[1mfix\e[0m"
	echo -e "\t\t\tExtract, fix and repackage the pk3s"
	echo -e "\t\t\e[1mname\e[0m"
	echo -e "\t\t\tPrint the file name of the output for \e[1mfix\e[0m"
	echo -e "\t\t\e[1mlist\e[0m"
	echo -e "\t\t\tPrint the name of the pk3 that need fixing and nothing more"
	echo_color 1 "\tOptions"
	echo -e "\t\t\e[1m--suffix=\e[22;4msuffix\e[0m"
	echo -e "\t\t\tSuffix to use for pk3 renaming"
	echo -e "\t\t\e[1m--no-suffix\e[0m"
	echo -e "\t\t\tDisable pk3 renaming (default)"
	echo_color 1 "\tOther"
	echo -e "\t\t\e[1mhelp\e[0m, \e[1m--help\e[0m, \e[1m-h\e[0m"
	echo -e "\t\t\tPrint this :-P"
	echo
}

# @brief if the given pk3 has to be fixed, add it to $fixable_list
function pk3_fix_list()
{
	pk3_check $1 >/dev/null
	if [ $? -ne 0 ]
	then
		fixable_list="$fixable_list $1"
	fi
}

action=pk3_check
RENAME_SUFFIX=
fixable_list=

if [ $# -eq 0 ]
then
	show_help
	exit
fi

if [ "$1" = "just-check" ]
then
	if [ $# -eq 2 ] && ( echo $2 | grep -q "\.pk3$" )
	then
		pk3_check $2
		exit $?
	else
		show_help
		exit -1
	fi
fi

for arg in $@
do
	case $arg in 
		check)
			action=pk3_check
			;;
		fix)
			action=pk3_fix
			;;
		name)
			action=pk3_fix_name
			;;
		list)
			action=pk3_fix_list
			;;
		--suffix=*)
			RENAME_SUFFIX=`echo $arg | sed 's/.*=//'`
			;;
		--no-suffix)
			RENAME_SUFFIX=
			;;
		help|--help|-h)
			show_help
			;;
		*.pk3)
			$action $arg
			;;
		*)
			echo Skipping unknown option $arg
			;;
	esac
done

if [ -n "$fixable_list" ]
then
	echo $fixable_list | sed "s/ /\n/g"
fi
#!/bin/bash
gametypes="dm tdm ft inf"
out_dir=~/.xonotic/data/maps


source $(dirname $(readlink -se "${BASH_SOURCE[0]}"))/pk3-utils-source.sh

function mapinfo()
{
	if [ ! -d $out_dir ]
	then
		mkdir -p $out_dir
	fi
	
	echo Checking $1...
	
	if ! pk3_is_map $1
	then
		echo "    not a map pk3"
		return 0
	fi
	
	maps=$(pk3_maps $1)
	declare -i issues
	let issues=0
	
	for map in $maps
	do
		map_name=`basename $map .bsp`
		mapinfo_file=$out_dir/$map_name.mapinfo
		echo "    Generating mapinfo for $map"
		
		if [ ! -f $mapinfo_file ]
		then
			if pk3_contains $1 maps/$map_name.mapinfo
			then
				unzip -p $1 maps/$map_name.mapinfo >$mapinfo_file
			else
				create_mapinfo $out_dir $map_name 7
			fi
		fi
		
		for gametype in $gametypes
		do
			if ! grep -qE "^(game)type\s+$gametype" $mapinfo_file
			then
				echo "        Adding $gametype"
				echo "gametype $gametype" >>$mapinfo_file
			fi
		done
	done
}

for arg in $@
do
	
	case $arg in
		*.pk3)
			mapinfo $arg
			;;
		*)
			echo Skipping unknown option $arg
			;;
	esac
done
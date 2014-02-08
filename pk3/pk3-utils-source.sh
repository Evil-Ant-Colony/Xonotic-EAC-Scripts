
# Directory containing these scripts
SCRIPT_INSTALLDIR=$(dirname $(readlink -se "${BASH_SOURCE[0]}"))


#suffix used to rename pk3s
RENAME_SUFFIX=_please_change_this_in_config
# rood directory where unwanted pk3 are to be moved
MOVETO_ROOT=~
#main xonotic data directory
XONOTIC_DATA_DIR=~/.xonotic/data
#all directory which contain pk3s
ALL_PK3_DIRS=($XONOTIC_DATA_DIR)

if [ -f "$SCRIPT_INSTALLDIR/config.sh" ]
then
	#use this to overwrite any of the variables defined above
	source $SCRIPT_INSTALLDIR/config.sh
fi


# @brief Prints a list of files in a pk3
# @param $1 pk3 name
function pk3_files()
{
	#unzip -l $1 | head -n -2 | tail -n +4 | sed -r s/^[^a-z]+//
	zipinfo -1 $1
}

# @brief returns whether a pk3 contains a file matching the given regex
# @param $1 pk3 name
# @param $2 regex pattern
function pk3_contains
{
	pk3_files $1 | grep -Eq $2
}

# @brief returns whether a pk3 contains a map (bsp)
# @param $1 pk3 name
function pk3_is_map()
{
	pk3_contains $1 "maps/.+\.bsp"
}

# @brief print all map files in a pk3
# @param $1 pk3 name
function pk3_maps()
{
	pk3_files $1 | grep "\.bsp"
}

# @brief Create a default mapinfo file
# @param $1 output dir
# @param $2 map name
# @param $3 cdtrack 
function create_mapinfo()
{
			cat >$1/$2.mapinfo <<MAPINFO
title $2
// description ...
// author ...
cdtrack $3
// has turrets
// has vehicles
has weapons
gametype dm
gametype lms
gametype ka
gametype kh
gametype ca
gametype tdm
gametype ft
gametype inf
// optional: fog density red green blue alpha mindist maxdist
// optional: settemp_for_type (all|gametypename) cvarname value
// optional: clientsettemp_for_type (all|gametypename) cvarname value
// optional: size mins_x mins_y mins_z maxs_x maxs_y maxs_z
// optional: hidden
MAPINFO
}

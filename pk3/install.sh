#!/bin/bash

SELFDIR=$(dirname $(readlink -se "${BASH_SOURCE[0]}"))
INSTALL_DIRS="~/ftp ~/.xonotic/data"
BROKEN_DIR=~/unused-pk3/broken
REPACKAGE_NAME=repackage.sh
REPACKAGE=$SELFDIR/repackage.sh
RENAME_SUFFIX=_eac1

source $SELFDIR/pk3-utils-source.sh

function show_help()
{
	echo -e "\e[1mNAME\e[0m"
	echo -e "\t$0 - Install pk3 files"
	echo
	echo -e "\e[1mSYNOPSIS\e[0m"
	echo -e "\t\e[1m$0\e[0m [\e[4moptions\e[0m...] \e[4mfile\e[0m..."
	echo -e "\t\e[1m$0\e[0m \e[1mhelp\e[0m|\e[1m-h\e[0m|\e[1m--help\e[0m"
	echo
	echo -e "\e[1mDESCRIPTION\e[0m"
	echo -e "\t\e[1m$0\e[0m calls \e[4m$REPACKAGE_NAME\e[0m to check and (if needed) fix the pk3."
	echo -e "\tpk3s that are broken or in an invalid format will be moved to" 
	echo -e "\t\e[1m$BROKEN_DIR\e[0m."
	echo -e "\tThen the fixed pk3s will be installed in the following directories:"
	for i_d in $INSTALL_DIRS
	do
		echo -e "\t * \e[1m$i_d\e[0m"
	done
	echo
	echo -e "\e[1mOPTIONS\e[0m"
	echo -e "\e[1m--server-pk3\e[22m|\e[1m+s\e[0m"
	echo -e "\tInstall both maps and serverpackages (off by default)"
	echo -e "\e[1m--no-server-pk3\e[22m|\e[1m-s\e[0m"
	echo -e "\tInstall only maps (default)"
	echo -e "\e[1m--delete=\e[22;4mmode\e[0m"
	echo -e "\tHow to check whether the original pk3 has to be removed. Possible values:"
	echo -e "\t *:\e[1mask\e[0m:Always ask
\t *:\e[1mdelete\e[0m:Always delete
\t *:\e[1mdelete-installed\e[0m:Delete if the map has been installed
\t *:\e[1mdelete-same\e[0m:Delete if the map has been installed without change (default)
\t *:\e[1mkeep\e[0m:Don't delete it" | column -t -c 3 -s ":"
	echo
}

if [ $# -eq 0 ]
then
	show_help
	exit
fi

install_serverpacks=false
delete_behaviour=delete-same

for arg in $@
do
	case $arg in 
		*.pk3)
			pk3=$arg
			installed=false
			installed_noprob=false
			
			if ! zipinfo -1 $pk3 >/dev/null 2>&1
			then
				echo -e "\e[31;1m$pk3\e[22m is a bad archive\e[0m"
				mv $pk3 $BROKEN_DIR
			else
				if $install_serverpacks || pk3_is_map $pk3
				then
					if ! $REPACKAGE just-check $pk3
					then
						$REPACKAGE fix --suffix=$RENAME_SUFFIX $pk3
						pk3=`$REPACKAGE name --suffix=$RENAME_SUFFIX $pk3`
					else
						installed_noprob=true
					fi
					
					for i_d in $INSTALL_DIRS
					do
						installed=true
						rm -f $i_d/`basename $pk3`
						cp $pk3 $i_d
					done
					
					echo -e "\e[34;1m$pk3\e[22m has been installed\e[0m"
				else
					echo -e "\e[31;1m$pk3\e[22m is not a map pk3\e[0m"
				fi
				
				case $delete_behaviour in
					ask)
						rm -i $arg
						;;
					delete)
						echo -e "Removing \e[1m$arg\e[0m (forced)"
						rm -f $arg
						;;
					delete-same)
						if $installed_noprob
						then
							echo -e "Removing \e[1m$arg\e[0m (Moved to installation dirs)"
							rm -f $arg
						else
							echo -e "Keeping \e[1m$arg\e[0m"
						fi
						;;
					delete-installed)
						if $installed
						then
							echo -e "Removing \e[1m$arg\e[0m (Moved to installation dirs)"
							rm -f $arg
						else
							echo -e "Keeping \e[1m$arg\e[0m (Not installed)"
						fi
						;;
					*)
						echo -e "Keeping \e[1m$arg\e[0m"
						;;
				esac
					
			fi
			;;
		help|--help|-h)
			show_help
			;;
		--server-pk3|\+s)
			install_serverpacks=true
			;;
		--no-server-pk3|-s)
			install_serverpacks=false
			;;
		--delete=*)
			delete_behaviour=${arg#*=}
			;;
		*)
			echo Skipping unknown option $arg
			;;
	esac
done

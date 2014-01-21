#!/bin/bash

INSTALL_DIRS="ftp xonotic-data"
BROKEN_DIR=broken
REPACKAGE=./repackage.sh
RENAME_SUFFIX=_eac1


function show_help()
{
	#Pseudo-man :-P
	echo -e "\e[1mNAME\e[0m"
	echo -e "\t$0 - Install pk3 files"
	echo
	echo -e "\e[1mSYNOPSIS\e[0m"
	echo -e "\t\e[1m$0\e[0m \e[4mfile\e[0m..."
	echo -e "\t\e[1m$0\e[0m \e[1mhelp\e[0m|\e[1m-h\e[0m|\e[1m--help\e[0m"
	echo
	echo -e "\e[1mDESCRIPTION\e[0m"
	echo -e "\t\e[1m$0\e[0m calls \e[4m$REPACKAGE\e[0m to check and (if needed) fix the pk3"
	echo -e "\tpk3s that are broken or in an invalid format will be moved to $BROKEN_DIR"
	echo -e "\tThen the fixed pk3s will be installed in the following directories:"
	for i_d in $INSTALL_DIRS
	do
		echo -e "\t * $i_d"
	done
	echo -e "\tAfter a successful installation will ask whether you want to remove the original file"
	echo
}

if [ $# -eq 0 ]
then
	show_help
	exit
fi

for arg in $@
do
	case $arg in 
		*.pk3)
			pk3=$arg
			
			if ! zipinfo -1 $pk3 >/dev/null 2>&1
			then
				echo -e "\e[31;1m$pk3\e[22m is a bad archive\e[0m"
				mv $pk3 $BROKEN_DIR
			else
				if ! $REPACKAGE just-check $pk3
				then
					$REPACKAGE fix --suffix=$RENAME_SUFFIX $pk3
					pk3=`$REPACKAGE name --suffix=$RENAME_SUFFIX $pk3`
				fi
				
				for i_d in $INSTALL_DIRS
				do
					rm -f $i_d/`basename $pk3`
					cp $pk3 $i_d
				done
				
				echo -e "\e[34;1m$pk3\e[22m has been installed\e[0m"
				rm -i $arg
			fi
			;;
		help|--help|-h)
			show_help
			;;
		*)
			echo Skipping unknown option $arg
			;;
	esac
done
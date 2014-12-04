#!/bin/bash

INSTALL_PACKAGES=(python3 php5-cli git tmux libgmp-dev bash-completion)
INSTALL_OPTIONAL=(geoip-database-contrib)

function check_system()
{
	echo "Checking system..."
	echo -n "apt-get: "
	if ! which apt-get
	then
		echo "(not found)"
		echo "This script currently works only on Debian and derivatives!"
		return 1
	fi
	
	return 0
}

function install_packages()
{
	apt-get -y install ${INSTALL_PACKAGES[*]}
	for p in ${INSTALL_OPTIONAL[*]}
	do
		apt-get -y install $p
	done
}

function post_install()
{
	MAKE_FLAGS="-j 8"

	cd ~
	! [ -d src ] && mkdir src
	cd src
	
	if [ -f ~/.ssh/id_rsa ]
	then
		echo "Found SSH keys"
		echo -n "Use SSH to clone? [y|n]"
		read SSH
		[ "$SSH" = 'y' ] && SSH=true
	else
		SSH=false
	fi
		
	echo "Downloading Xonotic"
	XON_REPO="http://de.git.xonotic.org/xonotic/xonotic.git"
	$SSH && XON_REPO="ssh://git@gitlab.com/xonotic/xonotic.git"
	git clone "$XON_REPO"
	
	echo "Downloading Modpack"
	MOD_REPO="https://github.com/MarioSMB/modpack.git"
	$SSH && MOD_REPO="git@github.com:MarioSMB/modpack.git"
	git clone "$MOD_REPO"
	
	echo "Downloading Borgy"
	BORGY_REPO="https://github.com/mbasaglia/Simple_IRC_Bot.git"
	$SSH && BORGY_REPO="git@github.com:mbasaglia/Simple_IRC_Bot.git"
	git clone "$BORGY_REPO" Melanobot
	
	if [ ! -d Xonotic-EAC-Scripts ]
	then
		echo "Downloading Scripts"
		SCRIPTS_REPO="https://github.com/Evil-Ant-Colony/Xonotic-EAC-Scripts.git"
		$SSH && SCRIPTS_REPO="git@github.com:Evil-Ant-Colony/Xonotic-EAC-Scripts.git"
		git clone "$SCRIPTS_REPO"
	fi
	
	echo "Building Xonotic"
	( cd xonotic && ./all update && ./all compile -0 dedicated $MAKE_FLAGS )
	
	echo "Building Modpack"
	( cd modpack/qcsrc && make QCC=~/src/xonotic/gmqcc/gmqcc $MAKE_FLAGS )
	
	echo "Setting up executables"
	! [ -d bin ] && mkdir bin
	ln -s "$PWD/Xonotic-EAC-Scripts/server/server" ~/bin
	ln -s "$PWD/xonotic/gmqcc/gmqcc" ~/bin
	echo >>.bashrc
	echo ". $PWD/Xonotic-EAC-Scripts/server/autocomplete.sh" >>.bashrc
	
	echo "All set!"

}

if ! check_system
then
	echo "System check failed, aborting!" >&2
	exit 1
fi

if [ "$(id -u)" -eq 0 ]
then
	echo "Executing as root"
	if [ -n "$1" ]
	then
		USER="$1"
	else
		USER=$(pwd | sed -r -e "s~/home/~~" -e "s~/.*~~")
	fi
	
	
	while true
	do
		if [ -n "$USER" ]
		then
			echo "Selected installation user: $USER"
			echo  -n "Confirm? [y|n] "
			read user_ok
			[ "$user_ok" = 'y' ] && break
		fi
		
		echo -n "Enter installation user name: "
		read USER
		id -u "$USER" || USER=
	done
	
	install_packages
	
	export -f post_install
	su $USER -c post_install
else
	echo "You are not root"
	echo -n "Apply post-installation changes? [y|n] "
	read post_install
	[ "$post_install" = 'y' ] && post_install
fi

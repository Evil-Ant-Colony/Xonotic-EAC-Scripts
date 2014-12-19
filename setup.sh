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

function download_repo()
{
	local repo
	if $SSH 
	then
		repo="$1"
	else
		repo="$2"
	fi
	
	local name=$(basename "$repo" .git)
	
	if [ -d "$name" ]
	then
		echo "Found $name"
	else
		echo "Downloading $name"
		git clone "$repo"
	fi
}

function post_install()
{
	MAKE_FLAGS="-j 8"

	
	if [ -f ~/.ssh/id_rsa ]
	then
		echo "Found SSH keys"
		echo -n "Use SSH to clone? [y|n]"
		read SSH
		[ "$SSH" = 'y' ] && SSH=true
	else
		SSH=false
	fi
	
	! [ -d ~/src ] && mkdir ~/src
	cd ~/src
	download_repo "http://de.git.xonotic.org/xonotic/xonotic.git" "ssh://git@gitlab.com/xonotic/xonotic.git"
	download_repo "https://github.com/MarioSMB/modpack.git"       "git@github.com:MarioSMB/modpack.git"
	download_repo "https://github.com/mbasaglia/Melanobot.git"    "git@github.com:mbasaglia/Melanobot.git"
	download_repo "https://github.com/Evil-Ant-Colony/Xonotic-EAC-Scripts.git" "git@github.com:Evil-Ant-Colony/Xonotic-EAC-Scripts.git"
	
	echo "Building Xonotic"
	( cd ~/src/xonotic && touch data/xonotic-maps.pk3dir.no && ./all update && ./all compile -0 dedicated $MAKE_FLAGS )
	
	echo "Building Modpack"
	( cd ~/src/modpack/qcsrc && make QCC=~/src/xonotic/gmqcc/gmqcc $MAKE_FLAGS )
	
	echo "Setting up executables"
	! [ -d ~/bin ] && mkdir ~/bin
	ln -s "$PWD/Xonotic-EAC-Scripts/server/server" ~/bin
	ln -s "$PWD/xonotic/gmqcc/gmqcc" ~/bin
	
	if ! grep -qF Xonotic-EAC-Scripts/server/autocomplete.sh ~/.bashrc
	then
		echo >>~/.bashrc
		echo ". $PWD/Xonotic-EAC-Scripts/server/autocomplete.sh" >>~/.bashrc
	fi
	
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
		INSTALL_USER="$1"
	else
		INSTALL_USER=$(pwd | sed -r -e "s~/home/~~" -e "s~/.*~~")
	fi
	
	
	while true
	do
		if [ -n "$INSTALL_USER" ]
		then
			echo "Selected installation user: $INSTALL_USER"
			echo  -n "Confirm? [y|n] "
			read user_ok
			[ "$user_ok" = 'y' ] && break
		fi
		
		echo -n "Enter installation user name: "
		read INSTALL_USER
		id -u "$INSTALL_USER" || INSTALL_USER=
	done
	
	install_packages
	
	echo "Setting up init.d"
	borgy_initd=borgy
	borgy_initd_file="/etc/init.d/$borgy_initd"
	cat >"$borgy_initd_file" <<INITD
#!/bin/sh
### BEGIN INIT INFO
# Provides:             borgy
# Required-Start:       \$local_fs \$network
# Required-Stop:        \$local_fs \$network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Description:          Borgy, the evil IRC bot
### END INIT INFO

sudo -u $INSTALL_USER bash /home/$INSTALL_USER/src/Melanobot/init.d/borgy $*
INITD
	chmod 755 "$borgy_initd_file"
	update-rc.d "$borgy_initd" defaults
	
	export -f post_install
	export -f download_repo
	su $USER -c post_install
else
	echo "You are not root"
	echo -n "Apply post-installation changes? [y|n] "
	read post_install
	[ "$post_install" = 'y' ] && post_install
fi

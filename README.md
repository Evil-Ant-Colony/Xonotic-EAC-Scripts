Scripts to help with Xonotic server administration
==================================================

cfg
---

Some reusable config aliases

pk3
---

Bash scripts to manage pk3 and maps

* **pk3-download**    Downloads pk3 to be used by the mod
* **pk3-find-map**    Search and perform actions on maps, --help to see all the options
* **pk3-gen-mapinfo** Generate and fix mapinfo for a list of pk3
* **pk3-grep**        Find pk3 containing a file matching a pattern, --help to see all the options
* **pk3-install**     Install pk3 and fix it if needed, --help to see all the options
* **pk3-repackage**   Check and convert map pk3, --help to see all the options
* **source-pk3-utils.sh** Contains definitions useful to the above scripts, sould not be executed explicitly

### Config ###

To configure the script create a file called **config.sh**, it can override some script defaults

Example:

```bash
#suffix used to rename pk3s
RENAME_SUFFIX=_eac1

# rood directory where unwanted pk3 are to be moved
MOVETO_ROOT=~/unused-pk3

#main xonotic data directory
XONOTIC_DATA_DIR=~/.xonotic/data

#all directory which contain pk3s
ALL_PK3_DIRS=($XONOTIC_DATA_DIR ~/ftp)

#script-specific variable overrides:
INSTALL_DELETE_BEHAVIOUR=delete-installed
GEN_MAPINFO_GAMETYPES="dm tdm ft kh inf"
```

rcon2irc
--------

Perl scripts to be used as rcon2irc.pl plugins

server
------

Bash scripts to manage server instances

### Config ###

Create a file called **server.conf**, it will be updated when you register a new server.

Example:

```bash
GAME_CMD="/opt/xonotic run dedicated"
GAME_PARAMS="-userdir ~/.xonotic -game data -game data/pk3"
register_server foo bar cfg/server-foo.cfg
```

### Installation ###

If you install _server_ in PATH, you can ass autocomplete.sh to ~/.bashrc to have autocompletion 

zzz-*
-----

Scripts to create some custom packages

### Config ###

Create a file called **config.mk** in each of the directories:

```make
# pk3 version template, will be updated automatically when the version number increases
VERSION=_eac2
# Directories to be copied into on make install
INSTALL_DIRS=~/.xonotic/data/pk3
# List of files and directories to be packaged
FILES=models scripts textures sound
```

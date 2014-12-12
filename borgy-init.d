#!/bin/sh
### BEGIN INIT INFO
# Provides:             borgy
# Required-Start:       $local_fs $network
# Required-Stop:        $local_fs $network
# Default-Start:        2 3 4 5
# Default-Stop:         0 1 6
# Description:          Borgyautostart
### END INIT INFO

# Aktionen
sudo -u $USER bash /home/$USER/src/Melanobot/init.d/borgy $*

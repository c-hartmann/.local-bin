#!/bin/bash

LANG='C.UTF-8'

# TODO
# - put the icon in a defined place.
#   somewhere in ~/.local/share?
# - rename to display-off

waitfor=${1:-5}
message="Turning off all displays in $waitfor seconds ..."
kdialog --title 'Display Off' --passivepopup "$message" $waitfor --icon "$HOME/Desktop/monitor-off-symbolic.svg"
printf '%s\n' "$message" 1>&2
sleep $waitfor

# https://askubuntu.com/questions/1316097/how-to-turn-off-the-monitor-via-command-on-wayland-kde-plasma
# >
# $ qdbus org.kde.kglobalaccel /component/org_kde_powerdevil invokeShortcut "Turn Off Screen"
# $ kscreen-doctor --dpms off (note: Wayland only – does not work on X11)
# $ dbus-send --session --print-reply --dest=org.kde.kglobalaccel  /component/org_kde_powerdevil org.kde.kglobalaccel.Component.invokeShortcut string:'Turn Off Screen'

# https://github.com/hopeseekr/BashScripts/blob/trunk/turn-off-monitors
# >
# busctl --user set-property org.gnome.Mutter.DisplayConfig /org/gnome/Mutter/DisplayConfig org.gnome.Mutter.DisplayConfig PowerSaveMode i 1 (Wayland)

# https://discuss.kde.org/t/plasma-monitor-power-save-command-in-x-11/4804
# >
# xset dpms force off
# /bin/dbus-send --session --print-reply --dest=org.kde.kglobalaccel  /component/org_kde_powerdevil org.kde.kglobalaccel.Component.invokeShortcut string:'Turn Off Screen'
# >
# both tested, both do the job!

off=false
typeset -u session="${XDG_SESSION_TYPE:-wayland}"
case $session in

	WAYLAND )
		# works on Wayland
		kscreen-doctor --dpms 'off' && off=true
		# works on Wayland and should work on X11 as well
		! $off \
		&& /bin/dbus-send \
		  --session \
		  --print-reply \
		  --dest=org.kde.kglobalaccel \
		  /component/org_kde_powerdevil \
		  org.kde.kglobalaccel.Component.invokeShortcut \
		  string:'Turn Off Screen' \
		  1>/dev/null
	;;

	X11 )
		# some say, it is not working in x11
		kscreen-doctor --dpms 'off' && off=true
		# this should work in X11 but obviously not in Wayland
		! $off && /usr/bin/xset dpms force off && off=true
		# works on Wayland and should work on X11 as well
		! $off \
		&& /bin/dbus-send \
		  --session \
		  --print-reply \
		  --dest=org.kde.kglobalaccel \
		  /component/org_kde_powerdevil \
		  org.kde.kglobalaccel.Component.invokeShortcut \
		  string:'Turn Off Screen' \
		  1>/dev/null
	;;

	* )
		printf '%s\n' "Error: Unknown session type: $session"
		exit 9
	;;

esac

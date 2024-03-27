
#! /usr/bin/env bash

# qdbus2dbus-send.bash

# convert qdbus command line syntax to send-bus syntax

# take all the aguments as you would give to qdbus and returns arguments for dbus-send

# KDE genrally comes with qdbus(1) installed but not always with that name. openSUSE
# is such an example, whereas it is named qdbus-qt5 (or similar ;)

# see: https://github.com/c-hartmann/D-Bus-the-mini-README


# qdbus usage:
# qdbus [--help] [--system] [--bus busaddress] [--literal] [servicename] [path] [method] [args]
#
#   servicename       the service to connect to (e.g., org.freedesktop.DBus)
#   path              the path to the object (e.g., /)
#   method            the method to call, with or without the interface
#   args              arguments to pass to the call
# With 0 arguments, qdbus will list the services available on the bus
# With just the servicename, qdbus will list the object paths available on the service
# With service name and object path, qdbus will list the methods, signals and properties
# available on the object
#
# Options:
#   --system          connect to the system bus
#   --bus busaddress  connect to a custom bus
#   --literal         print replies literally


# dbus-send usage:
# dbus-send [--help] [--system | --session | --bus=ADDRESS | --peer=ADDRESS] [--dest=NAME] [--type=TYPE] \
#           [--print-reply[=literal]] [--reply-timeout=MSEC] <destination object path> <message name> [contents ...]

command="dbus-send"

# eval long options
OPTS=$(getopt --name $(basename "$0") \
			--options hsb:l: --longoptions help,system,bus:,literal \
              -- "$@")

[[ $? != 0 ]] && exit 9

# defaults for dbus-send
bus="" # qdbus and dbus-send both defaults to the session message bus
bus_address=""
peer=""
dest=""
type="--type=method_call" # dbus-send defaults to "signal", but qdbus to method
print_reply=""
# print_reply="--print-reply" # TODO: shall we use it? no default
reply_timeout=""
destination_object_path=""
#destination=""
#object=""
#path=""
message_name=""
contents=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--help )
			echo "Usage: $(basename "$0") [--system] [--bus busaddress] [--literal] [servicename] [path] [method] [args]"
			exit 1
			;;
		--system )
			bus="--system"
			shift 1
			;;
		--bus )
			bus_address="--bus=$2"
			shift 2
			;;
		--literal )
			print_reply="--print-reply=literal"
			shift 1
			;;
		# any arguments not matching the above ones are consired to be the remaining names in qdbus' required order: [servicename] [path] [method] [args]
		* )
			break
			;;
	esac
done

# the remaining arguments (using qdbus terms): [servicename] [path] [method] [args]
# set -x
servicename=$1; shift 1
path=$1; shift 1
method=$1; shift 1
args="$@"

# maping to dbus-send
dest="--dest=$servicename"
destination_object_path=$path
message_name=$method
contents="$args"

# dbus-send [--help] [--system | --session | --bus=ADDRESS | --peer=ADDRESS] [--dest=NAME] [--type=TYPE] \
#           [--print-reply[=literal]] [--reply-timeout=MSEC] <destination object path> <message name> [contents ...]
echo dbus-send $bus $bus_address $peer $dest $type $print_reply $destination_object_path $message_name $contents

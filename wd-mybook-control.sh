#!/bin/bash

# wd-mybook-control.sh

LANG=C
ME=$(basename "$0")
USB_DEV_ADDR_TMP_FILE=/tmp/backup-on-haltinit.usb_dev_addr

### initialize dialog type
declare gui
declare cli
if [[ ! -t 0 ]]; then
	# running via service menu
	gui=true
	cli=false
else
	# running in command line
	gui=false
	cli=true
fi

_exit_on_error ()
{
	$cli && echo "Error: $1" >&2
	$gui && $gui && kdialog --title "backup on halt" --icon=backup --msgbox "Error: $1" &
	exit 1
}

# default mode is: "on". command line takes precedence
mode='on'
(( $# > 0 )) && mode="$1"
[[ "$mode" =~ ^on|off|mount$ ]] || _exit_on_error "command shall be 'on', 'off' or 'mount'"



# $ lsusb -t
# /:  Bus 04.Port 1: Dev 1, Class=root_hub, Driver=xhci_hcd/6p, 5000M
#     |__ Port 2: Dev 2, If 0, Class=Mass Storage, Driver=, 5000M

# $ udisksctl status
# MODEL                     REVISION  SERIAL               DEVICE
# --------------------------------------------------------------------------
# WDC WD5000BMVV-11GNWS0    01.01A01  WD-WX31A80R2031      sdd           <- Elements
# WD My Book 1140           1019      504C323333314C4147375544414A sdg   <- MyBook


### CASE...
# lsusb DOES lists MyBook
# but udisksctl status does NOT
# device is obviously sleeping (disk is not spining) and device is not present in plasma USB widget
# device in /dev/ eventualy present or not present - likely it was sdd and this is not there
# $ ll /dev/disk/by-id/ - nothing there
# >> WTF :)

# $ usbreset
# Usage:
#   usbreset PPPP:VVVV - reset by product and vendor id   <- seems PPPP and VVVV are swapped
#   usbreset BBB/DDD   - reset by bus and device number
#   usbreset "Product" - reset by product name
#
# Devices:
#   Number 003/014  ID 1058:1023  Elements 1023
#   Number 004/002  ID 1058:1140  My Book 1140

# $ sudo usbreset 1058:1023
# Resetting Elements 1023 ... ok
# > fine

# $ sudo usbreset 1058:1040

# $ sudo uhubctl
# Current status for hub 2-1 [8087:8001]
#   Port 1: 0100 power
#   Port 2: 0100 power
#   Port 3: 0100 power
#   Port 4: 0100 power
#   Port 5: 0100 power
#   Port 6: 0100 power
#   Port 7: 0100 power
#   Port 8: 0100 power
# Current status for hub 1-1 [8087:8009]
#   Port 1: 0100 power
#   Port 2: 0100 power
#   Port 3: 0100 power
#   Port 4: 0100 power
#   Port 5: 0100 power
#   Port 6: 0503 power highspeed enable connect [0424:2502]


# next is from: https://stackoverflow.com/questions/18765725/turning-off-a-single-usb-device-again
# $ sudo usb_modeswitch -v 0x7392 -p 0x7811 --reset-usb

# with:
ID_VENDOR="1058"
ID_PRODUCT="1140"

# it would be:
# $ sudo usb_modeswitch -v 0x1058 -p 0x1140 --reset-usb

# running it gives me that:
# Look for default devices ...
#  Found devices in default mode (1)
# Access device 002 on bus 004
# Get the current device configuration ...
# Current configuration number is 1
# Use interface number 0
#  with class 8
# Warning: no switching method given. See documentation
# Reset USB device .
#  Device was reset
# -> Run lsusb to note any changes. Bye!

# $ usb_modeswitch
#
# Usage: usb_modeswitch [<params>] [-c filename]
#
#  -h, --help                    this help
#  -e, --version                 print version information and exit
#  -j, --find-mbim               return config no. with MBIM interface, exit
#
#  -v, --default-vendor NUM      vendor ID of original mode (mandatory)
#  -p, --default-product NUM     product ID of original mode (mandatory)
#  -V, --target-vendor NUM       target mode vendor ID (optional)
#  -P, --target-product NUM      target mode product ID (optional)
#  -C, --target-class NUM        target mode device class (optional)
#  -b, --bus-num NUM             system bus number of device (for hard ID)
#  -g, --device-num NUM          system device number (for hard ID)
#  -m, --message-endpoint NUM    direct the message transfer there (optional)
#  -M, --message-content <msg>   message to send (hex number as string)
#  -2, --message-content2 <msg>  additional messages to send (-n recommended)
#  -3, --message-content3 <msg>  additional messages to send (-n recommended)
#  -w, --release-delay NUM       wait NUM ms before releasing the interface
#  -n, --need-response           obsolete, no effect (always on)
#  -r, --response-endpoint NUM   read response from there (optional)
#  -K, --std-eject               send standard EJECT sequence
#  -d, --detach-only             detach the active driver, no further action
#  -H, --huawei-mode             apply a special procedure
#  -J, --huawei-new-mode         apply a special procedure
#  -X, --huawei-alt-mode         apply a special procedure
#  -S, --sierra-mode             apply a special procedure
#  -O, --sony-mode               apply a special procedure
#  -G, --gct-mode                apply a special procedure
#  -N, --sequans-mode            apply a special procedure
#  -A, --mobileaction-mode       apply a special procedure
#  -T, --kobil-mode              apply a special procedure
#  -L, --cisco-mode              apply a special procedure
#  -B, --qisda-mode              apply a special procedure
#  -E, --quanta-mode             apply a special procedure
#  -F, --pantech-mode NUM        apply a special procedure, pass NUM through
#  -Z, --blackberry-mode         apply a special procedure
#  -U, --option-mode             apply a special procedure
#  -R, --reset-usb               reset the device after all other actions
#  -Q, --quiet                   don't show progress or error messages
#  -W, --verbose                 print all settings and debug output
#  -D, --sysmode                 specific result and syslog message
#  -s, --check-success <seconds> switching result check with timeout
#  -I, --inquire                 obsolete, no effect
#
#  -c, --config-file <filename>  load long configuration from file
#
#  -t, --stdinput                read long configuration from stdin
#
#  -f, --long-config <text>      get long configuration from string
#
#  -i, --interface NUM           select initial USB interface (default 0)
#  -u, --configuration NUM       select USB configuration
#  -a, --altsetting NUM          select alternative USB interface setting
#
#
#  * usb_modeswitch: handle USB devices with multiple modes
#  * Version 2.5.2 (C) Josua Dietze 2017
#  * Based on libusb1/libusbx
#
#  ! PLEASE REPORT NEW CONFIGURATIONS !


ID_VENDOR="1058"
ID_PRODUCT="1140"
_checkdisk()
{
	echo "checking usb device: ${ID_VENDOR}:${ID_PRODUCT}..." >&2
	# one of these:
	lsusb | grep "${ID_VENDOR}:${ID_PRODUCT}" && _exit_on_error "USB Device $ID_VENDOR:$ID_PRODUCT already in use. nothing to do"
	#udisksctl status | grep "$DEVICE"
}


USB_DEVICE_BUS_ADDR="$(cat "${USB_DEV_ADDR_TMP_FILE}")"
if $gui; then
	export SUDO_ASKPASS="$HOME/.bin/ask-pass.sh"
# 	sudo --askpass true
	sudo="sudo --askpass"
else
	sudo=sudo
fi
_wake_up_device ()
{
# 	[[ $gui ]]; then
# 		export SUDO_ASKPASS="$HOME/.bin/ask-pass.sh"
# 		sudo --askpass true
# 	else
# 		sudo true
# 	fi
	$sudo true
	echo "waking device up: ${USB_DEVICE_BUS_ADDR}..." >&2
	echo "binding usb device: ${USB_DEVICE_BUS_ADDR}..." >&2
	echo "using: echo -n ${USB_DEVICE_BUS_ADDR} | sudo tee -a /sys/bus/usb/drivers/usb/bind"
	echo -n "${USB_DEVICE_BUS_ADDR}"     | sudo tee -a /sys/bus/usb/drivers/usb/bind
	#sudo sh -c "echo -n ${USB_DEVICE_BUS_ADDR}     >> /sys/bus/usb/drivers/usb/bind"
	#echo "binding usb storage: ${USB_DEVICE_BUS_ADDR}:1.0..." >&2
	#echo -n "${USB_DEVICE_BUS_ADDR}:1.0" | sudo tee -a /sys/bus/usb/drivers/usb-storage/bind
	#sudo sh -c "echo -n ${USB_DEVICE_BUS_ADDR}:1.0 >> /sys/bus/usb/drivers/usb/bind"
}

_send_to_sleep_device ()
{
	$sudo true
	echo "sending device to sleep: ${USB_DEVICE_BUS_ADDR}..." >&2
	echo "unbinding usb storage: ${USB_DEVICE_BUS_ADDR}:1.0..." >&2
	sudo sh -c "echo -n ${USB_DEVICE_BUS_ADDR}:1.0 >> /sys/bus/usb/drivers/usb/unbind"
}

_mount_device ()
{
	mount | grep 'MyBook' >/dev/null && echo "MyBook already mounted" &&  return
	disk=$(udisksctl status | grep 'WD My Book' | awk '{printf $7;}')
	udisksctl mount -b "/dev/${disk}1"
}

# if device is ready to mount or break with error
#_wake_up_device
#_checkdisk || _wake_up_device

[[ "$mode" == 'on' ]]  && _wake_up_device
[[ "$mode" == 'off' ]] && _send_to_sleep_device
[[ "$mode" == 'mount' ]] && _mount_device

# exit here
exit 0

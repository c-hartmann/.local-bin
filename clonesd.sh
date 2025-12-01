#!/bin/bash
### clonesd.sh
### create a clone of a SD card on another sd card
### TODO shall this take disk or partitions devices? > partitions

function _usage
{
	cat << "	EOU"
	usage: clonesd.sh <from> <to>
	EOU
}

function _error
{
	local text="$1"
#	local -i code=$2
	echo "$text" >&2
	echo
}

# function _error_exit
# {
# 	local text="$1"
# 	local -i code=$2
# 	echo "$text" >&2
# 	echo
# 	_usage
# 	# shellcheck disable=SC2086
# 	exit $code
# }

#_error "minimum of two arguments required"; _usage; exit 1

### minimum of two arguments
[[ $# -ge 2 ]] || { _error "minimum of two arguments required"; _usage; exit 1; }

### arguments shall not be equal
[[ $1 != $2 ]] || { _error "arguments shall not be equal" ; _usage; exit 2; }

### extract block device (aka partition) name part
sd1="${1##*/}"
sd2="${2##*/}"

### devices shall not be equal
[[ $sd1 != $sd2 ]] || { _error "devices shall not be equal" ; _usage; exit 3; }

### from an to shall be present and be block devices
[[ -b "/dev/$sd1" ]] || { _error "<from> source is not a block device" ; _usage; exit 5; }
[[ -b "/dev/$sd2" ]] || { _error "<to> target is not a block device" ;   _usage; exit 5; }

### get the bare device part of our partitions
d1="${sd1%%[0-9]*}"
d2="${sd2%%[0-9]*}"

### this uses partitions not devices as the sources
[[ $sd1 != $d1 ]] || { _error "<from> source is not a partition" ; _usage; exit 4; }
[[ $sd2 != $d2 ]] || { _error "<to> target is not a partition" ;   _usage; exit 4; }

### get block sizes of devices used
declare -i bs1
declare -i bs2
bs1=$(cat /sys/block/"$d1"/queue/hw_sector_size)
bs2=$(cat /sys/block/"$d2"/queue/hw_sector_size)

### get a secure temporary file
# tf="$(mktemp)"

### get mountpoint of <to> partition and ask user to confirm overwriting
mp2=$(lsblk /dev/$sd2 | tail -1 | awk '{print $7}')
read -p "Overwrite and delete all data on $mp2 ? (yes|No) "
[[ $REPLY == "yes" ]] || exit 99

### copy from sd card, to temporary file and from there to sd card
# shellcheck disable=SC2086
dd if="/dev/$sd1" of="$tf"  bs=$bs1 status=progress
mp1=$(lsblk /dev/$sd1 | tail -1 | awk '{print $7}')
mp1n=${mp1##*/}
mv "$tf" "${mp1n}.img"
chmod 644 "${mp1n}.img"
echo "copy of source created to: ${mp1n}.img"
# this will mount the image
udisksctl loop-setup -f $PWD/${mp1n}.img
udisksctl mount -b /dev/loop0
exit

# shellcheck disable=SC2086
# dd if="$tf"  of="/dev/$sd2" bs=$bs2 status=progress

### or in just one step without temporary file
udisksctl unmount "/dev/$sd2"
# shellcheck disable=SC2086
dd if="/dev/$sd1" ibs=$bs1 of="/dev/$sd2" obs=$bs2 status=progress

### remove temporary file
# rm $tf 2>/dev/null

### clean exit
exit 0

#!/bin/bash

# internal ip:

# nmcli --fields TYPE,DEVICE connection show
# >
# TYPE      DEVICE
# ethernet  enp0s25
# bridge    br-fed9bcb43dcb
# bridge    docker0
# bridge    virbr0
#
# nmcli --fields TYPE,DEVICE connection show | grep '^ethernet'
# >
# ethernet  enp0s25
#
# nmcli --fields TYPE,DEVICE connection show | grep '^ethernet' | awk '{print $2}'
# >
# enp0s25
#
# ifconfig enp0s25 | grep 'inet ' | awk '{print $2}'
# >
# 192.168.178.53


device=$(nmcli --fields TYPE,DEVICE connection show | grep '^ethernet' | head -1 | awk '{print $2}')
printf '%s\n' 'device:'
	printf '\t'
	printf '%s\n' "$device"

# IP4
printf '%s\n' 'privat (IP4):'
if type -p ifconfig; then
	printf '\t'
	ifconfig $device | grep 'inet ' | awk '{print $2}'
else
	printf '\t'
	ip -4 addr show dev $device | awk '{if ($1=="inet") {print $2}}'
fi
# IP6
printf '%s\n' 'privat (IP6):'
	printf '\t'
	ip -6 addr show dev $device | awk '{if ($1=="inet6") {print $2}}'

# IP4
printf '%s\n' 'public (IP4):'
	printf '\t'
	curl -4 ifconfig.co
# IP6
printf '%s\n' 'public (IP6):'
	printf '\t'
	curl -6 ifconfig.co

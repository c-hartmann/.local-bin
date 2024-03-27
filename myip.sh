#!/bin/sh

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

printf '%s\n' 'privat:'
# IP4
device=$(nmcli --fields TYPE,DEVICE connection show | grep '^ethernet' | awk '{print $2}')
ifconfig $device | grep 'inet ' | awk '{print $2}'
# IP6
ip -6 addr show dev $device | awk '{if ($1=="inet6") {print $2}}'

printf '%s\n' 'public:'
# IP4
curl -4 ifconfig.co
# IP6
curl -6 ifconfig.co

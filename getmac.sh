  ip link | grep link | awk '{ printf "%-20s %s\n", $1, $2 }'

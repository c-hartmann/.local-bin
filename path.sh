#!/bin/bash
# credit:
# https://stackoverflow.com/questions/11655770/looping-through-the-elements-of-a-path-variable-in-bash
# https://stackoverflow.com/users/1815797/gniourf-gniourf
IFS=: read -r -d '' -a path_array < <(printf '%s:\0' "$PATH")
for p in "${path_array[@]}"; do
    printf '%s\n' "$p"
done
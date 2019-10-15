#!/usr/bin/env bash

set -euo pipefail

input_definition="$1" && shift

lines=( $(grep --line-number "symbol Lbl'Hash'EmptyK{}() :"     "$input_definition" | cut --delimiter=':' --field=1 | tail -n +2))
lines+=($(grep --line-number "symbol Lbl'Hash'EmptyKList{}() :" "$input_definition" | cut --delimiter=':' --field=1 | tail -n +2))

sed_command=''

for line in ${lines[@]}; do
    sed_command="${sed_command}${line}d;"
done

sed -i "$sed_command" "$input_definition"

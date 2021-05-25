#!/bin/bash
MOD_DIR="$(dirname "$(readlink -f "$0")")"
SRM_DIR="$MOD_DIR/srm"
shopt -s nullglob

cp -vf /dev/null "$SRM_DIR"/root/.ssh/authorized_keys
for k in "$MOD_DIR"/*.pub; do
    printf "Adding ssh key from %q.\n" "$k" >&2
    cat "$k" >> "$SRM_DIR"/root/.ssh/authorized_keys
done

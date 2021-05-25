#!/bin/bash
set -e -u
umask 0022
MODULES_DIR="$(dirname "$(readlink -f "$0")")"
cd "$MODULES_DIR"
SRM_DIR=$(mktemp -d srm.XXXXXX)
SRM_OUT="$sr_src/srm/modules.srm"

# create package list needed for building SRMs
for m in $srm_enabled; do
    if [ -f "$m"/packages.txt ]; then
        cat "$m"/packages.txt >> packages.txt
    fi
done

# install packages needed for building SRMs
if [ -f packages.txt ]; then
    packages_temp=$(mktemp packages.XXXXXX)
    sort packages.txt | uniq > "$packages_temp"
    mv -f "$packages_temp" packages.txt

    printf "Installing additional packages for SRMs:\n" >&2
    sed 's/^/\t- /' packages.txt >&2
    echo pacman --noconfirm -S $(cat packages.txt)
fi

# bootstrap SRMs
for m in $srm_enabled; do
    if [ -x "$m"/bootstrap.sh ]; then
        printf "Running bootstrap script for SRM \"%s\".\n" "$m" >&2
        "$m"/bootstrap.sh
    else
        printf "No bootstrap script for SRM \"%s\".\n" "$m" >&2
    fi
    rsync -avPh "$m"/srm/ "$SRM_DIR"/
done

# create a single SRM image
# NB: Currently SystemRescue doesn't support selectively loading SRMs.
#     It is therefore more efficient to create a single SRM image
#     containing everything, rather than one image per SRM.
if (( $(find "$SRM_DIR" | wc -l) > 1 )); then
    printf "Creating SRM image \"%s\" from \"%s\".\n" "$SRM_OUT" "$SRM_DIR" >&2
    mksquashfs "$SRM_DIR" "$SRM_OUT" -noappend -comp xz
    printf "Cleaning up \"%s\".\n" "$SRM_DIR" >&2
    rm -rvf "$SRM_DIR"
else
    printf "Skipping creation of SRM image.\n" >&2
    printf "Cleaning up SRM files.\n" >&2
    rm -rvf "$SRM_DIR" "$SRM_OUT"
fi      

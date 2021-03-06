#!/bin/bash

# Answer file templates: https://github.com/boxcutter/windows/tree/master/floppy

# Optional: Validate answer file with Windows AIK/ADK (Must add cpi:offlineImage tag to answer file referencing the CLG or WIM file embedded in the ISO)

# Get product key: https://github.com/mrpeardotnet/WinProdKeyFinder/releases
# Install desired edition (Home, Ultimate, Pro, etc.) of any given Windows media manually then proceed to run WinProdKeyFinder to get the trial key and use it in the answer file
# Specifying a key is not required for "Evaluation" Windows media

# Update: Found a way to avoid hardcoding the product key for any version/edition of Windows which is great because it makes the answer files more adaptable to working with any given Windows media
# Also, we don't have to do the tedious work of installing the Windows media manually then running that tool to get the trial product key

# Test for 4-bit color (16 colors)
if [ "0$(tput colors 2> /dev/null)" -ge 16 ]; then
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

usage() {
    echo "Usage: ${0} iso answer_file"
}

for arg in "$@"; do
    if [ "$arg" == "-h" ] ||  [ "$arg" == "--help" ]; then
        usage
        exit
    fi
done

if [ "$#" != "2" ]; then
    usage >&2
    exit 1
fi

iso="$1"
answer_file="$2"

if ! [ -f "$iso" ]; then
    echo -e "${RED}[!]${NC} ISO file not found: $iso" >&2
    exit 1
fi

if ! [ -f "$answer_file" ]; then
    echo -e "${RED}[!]${NC} Answer file not found: $answer_file" >&2
    exit 1
fi

cleanup() {
    exit_code="$?"

    if [ "$iso_device" ]; then
        echo -e "${BLUE}[i]${NC} Unmounting and deleting loop device..." >&2
        udisksctl unmount -b "$iso_device"
        udisksctl loop-delete -b "$iso_device"
    fi

    if [ -d "$temp_dir" ]; then
        echo -e "${BLUE}[i]${NC} Deleting temporary folder..." >&2
        chmod -R +w "$temp_dir" # Read-only permissions were inherited because ISO 9660 is a read-only format
        rm -r "$temp_dir"
    fi

    if [ "$exit_code" != 0 ]; then
        if [ -f "$final_iso" ]; then
            echo -e "${BLUE}[i]${NC} Deleting incomplete ISO output..." >&2
            rm "$final_iso"
        fi

        exit "$exit_code"
    fi
}

trap cleanup ERR INT

echo -e "${BLUE}[i]${NC} Creating loop device from ISO..." >&2
iso_device="$(udisksctl loop-setup -f "$iso")"
iso_device="${iso_device#Mapped file * as }"
iso_device="${iso_device%.}"

echo -e "${BLUE}[i]${NC} Mounting loop device..." >&2
# Fix race condition where disk tries to mount before finishing setup
until iso_mntpoint="$(udisksctl mount -b "$iso_device")"; do
    sleep 1
done
iso_mntpoint="${iso_mntpoint#Mounted * at }"
iso_mntpoint="${iso_mntpoint%.}"

echo -e "${BLUE}[i]${NC} Copying loop device contents to temporary folder..." >&2
temp_dir="$(mktemp -dp out)" # tmpfs on /tmp may be too small
cp -r "$iso_mntpoint/." "$temp_dir"

echo -e "${BLUE}[i]${NC} Copying answer file to Autounattend.xml in temporary folder..." >&2
cp "$answer_file" "$temp_dir/Autounattend.xml"

echo -e "${BLUE}[i]${NC} Creating new ISO..." >&2
# https://rwmj.wordpress.com/2010/11/04/customizing-a-windows-7-install-iso
# https://theunderbase.blogspot.com/2013/03/editing-bootable-dvds-as-iso-images.html

# Get boot image
geteltorito -o "$temp_dir/boot.bin" "$iso"

final_iso="${iso/isos/out}"
# -allow-limited-size allows for bigger files such as the install.wim which is the Windows image
genisoimage -udf -b boot.bin -no-emul-boot -allow-limited-size -quiet -o "$final_iso" "$temp_dir"

cleanup

echo -e "${GREEN}[+]${NC} Created automatic Windows installation media for $(basename "$final_iso") successfully!"

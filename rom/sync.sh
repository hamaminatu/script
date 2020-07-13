#!/bin/bash
#
# Copyright (c) 2020 azrim

# Init
ROM=zenx
MANIFEST="https://github.com/ZenX-OS/android_manifest.git"
BRANCH=ten
LOC_MANIFEST="https://github.com/hamaminatu/local_manifests.git"
LOC_BRANCH=master

TOKEN=""
CHAT_ID="-1001257379482"

# workdir
FOLDER=$HOME/$ROM

if ! [ -d "$FOLDER" ]; then
    mkdir "$FOLDER"
fi

cd "$FOLDER"

# Check if already init before
if ! [ -f "$FOLDER"/.repo/manifest.xml ]; then
    repo init -u "$MANIFEST" -b "$BRANCH"
fi

# cloning local manifest
if [ -f "$FOLDER"/.repo/local_manifests/local_manifest.xml ]; then
    rm -rf "$FOLDER"/.repo/local_manifests
fi

cd "$FOLDER"/.repo
git clone "$LOC_MANIFEST" -b "$LOC_BRANCH"
cd "$FOLDER"

# Finnaly start syncing
SYNC_START=$(date +"%s")

if [ -f "$FOLDER"/Makefile ]; then
    rm -rf "$FOLDER"/Makefile
fi

msg=$(mktemp)
{
  echo "*Syncing $ROM*"
  echo "Start Time: $(date +"%Y-%m-%d %H:%M")"
} > "${msg}"
MESSAGE=$(cat "$msg")

curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="$MESSAGE" https://api.telegram.org/bot${TOKEN}/sendMessage
repo sync -c -q --force-sync --optimized-fetch --no-tags --no-clone-bundle --prune -j$(nproc --all)

if ! [ -f "$FOLDER"/Makefile ]; then
    curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="Failed sync $ROM" https://api.telegram.org/bot${TOKEN}/sendMessage
    exit 1
fi

SYNC_END=$(date +"%s")
DIFF=$(($SYNC_END - $SYNC_START))

msg1=$(mktemp)
{
  echo "*Sync Finished*"
  echo ""
  echo "*Time:* $(($DIFF / 60)) minutes and $(($DIFF % 60)) seconds"
  echo "Ready to cook"
} > "${msg1}"
MESSAGE1=$(cat "$msg1")
curl -s -X POST -d chat_id=$CHAT_ID -d parse_mode=markdown -d text="$MESSAGE1" https://api.telegram.org/bot${TOKEN}/sendMessage

exit 1
#END

#!/bin/bash
# Copyrights (c) 2020 azrim.
#

# Init
FOLDER="${PWD}"
OUT="${FOLDER}/out/target/product/ginkgo"

# ROM
ROMNAME="ZenX-OS"                   # This is for filename
ROM="zenx"                        # This is for build
DEVICE="ginkgo"
TARGET="userdebug"
VERSIONING="FLOKO_BUILD_TYPE"
VERSION="Unofficial"
CLEANING=""                          # set "clean" for make clean, "clobber" for make clean && make clobber, don't set for dirty build

# TELEGRAM
CHATID="-1001257379482"                            # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN=""                    # Get from botfather

# Export Telegram.sh
TELEGRAM_FOLDER="${HOME}"/telegram
if ! [ -d "${TELEGRAM_FOLDER}" ]; then
    git clone https://github.com/fabianonline/telegram.sh/ "${TELEGRAM_FOLDER}"
fi

TELEGRAM="${TELEGRAM_FOLDER}"/telegram

tg_cast() {
    "${TELEGRAM}" -t "${TELEGRAM_TOKEN}" -c "${CHATID}" -H \
    "$(
		for POST in "${@}"; do
			echo "${POST}"
		done
    )"
}

# cleaning env
cleanup() {
    if [ -f "$OUT"/*.zip ]; then
        rm "$OUT"/*.zip
    fi
    if [ -f gd-up.txt ]; then
        rm gd-up.txt
    fi
    if [ -f gd-info.txt ]; then
        rm gd-info.txt
    fi
    if [[ "${CLEANING}" =~ "clean" ]]; then
        make clean
	build
    elif [[ "${CLEANING}" =~ "clobber" ]]; then
        make clean && make clobber
	build
    else
        build
    fi
}

# Build
build() {
    # export "${VERSIONING}"="${VERSION}"
    source build/envsetup.sh
    export CCACHE_DIR=./.ccache
    ccache -C
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    ccache -M 50G
    export LC_ALL=C
    lunch "${ROM}"_"${DEVICE}"-"${TARGET}"
    brunch "${DEVICE}" 2>&1 | tee log.txt
}

# Checker
check() {
    if ! [ -f "$OUT"/*$VERSION*.zip ]; then
        END=$(date +"%s")
        DIFF=$(( END - START ))
        tg_cast "${ROMNAME} Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!" \
	        "Check log below"
        "${TELEGRAM}" -f log.txt -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
	# self_destruct
    else
        success
    fi
}

# Self destruct
self_destruct() {
    tg_cast "I will shutdown myself in 30m, catch me if you can :P"
    sleep 30m
    sudo shutdown -h now
}

# done
success() {
    END=$(date +"%s")
    DIFF=$(( END - START ))
    tg_cast "<b>ROM Build Completed Successfully</b>" \
            "Build took $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)!" \
            "------------------------------------------------" \
            "ROM: <code>${ROMNAME} for ${DEVICE}</code>" \
            "Date: <code>${BUILD_DATE}</code>"
    "${TELEGRAM}" -f log.txt -t "${TELEGRAM_TOKEN}" -c "${CHATID}"
    # self_destruct
}

# Let's start
BUILD_DATE="$(date +"%Y-%m-%d %H:%M")"
START=$(date +"%s")
tg_cast "<b>STARTING ROM BUILD</b>" \
        "ROM: <code>${ROMNAME}</code>" \
        "Device: <code>${DEVICE}</code>" \
        "Version: <code>${VERSION}</code>" \
        "Build Start: <code>${BUILD_DATE}</code>"
cleanup
check

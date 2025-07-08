#!/bin/bash

# Source include file
. ./scripts/INCLUDE.sh

# Exit on error
set -e

# Display profile information
make info

# Validasi
PROFILE=""
PACKAGES=""
EXCLUDED=""

# Base - Core - Luci
PACKAGES+=" libc bash block-mount coreutils-stat coreutils-stty"
PACKAGES+=" wget-ssl unzip parted resize2fs losetup"
PACKAGES+=" zram-swap adb lolcat uhttpd uhttpd-mod-ubus"
PACKAGES+=" luci luci-base luci-mod-admin-full luci-lib-ip luci-compat luci-ssl"

# Hardware support - USB and LAN networking drivers
PACKAGES+=" kmod-usb-net-rtl8152"
PACKAGES+=" kmod-usb-net kmod-usb-net-rndis"
PACKAGES+=" kmod-usb2"
PACKAGES+=" kmod-usb3"

add_tunnel_packages() {
    local option="$1"
    case "$option" in
        openclash)
            PACKAGES+=" $OPENCLASH"
            ;;
        openclash-nikki)
            PACKAGES+=" $OPENCLASH $NIKKI"
            ;;
        openclash-nikki-passwall)
            PACKAGES+=" $OPENCLASH $NIKKI $PASSWALL"
            ;;
        "")
            # tidak menambah tunnel packages
            ;;
    esac
}

# Storage - NAS
PACKAGES+=" kmod-usb-storage kmod-usb-storage-uas ntfs-3g luci-app-diskman"

# Monitoring - Autorekonek
PACKAGES+=" internet-detector luci-app-internet-detector vnstat2 vnstati2 luci-app-netmonitor"

# Theme - UI
PACKAGES+=" luci-theme-argon"

# PHP packages
PACKAGES+=" php8 php8-fastcgi php8-mod-session php8-mod-fileinfo php8-mod-zip php8-mod-mbstring php8-mod-json php8-mod-gd"

# Custom Packages
PACKAGES+=" luci-app-ipinfo luci-app-mactodong luci-app-poweroffdevice"
PACKAGES+=" luci-app-ramfree luci-app-tinyfm luci-app-ttyd"

# Profil Name
configure_profile_packages() {
    local profile_name="$1"

    if [[ "$profile_name" == "rpi-4" ]]; then
        PACKAGES+=" kmod-i2c-bcm2835 i2c-tools kmod-i2c-core kmod-i2c-gpio"
    fi

    if [[ "${ARCH_2:-}" == "x86_64" ]] || [[ "${ARCH_3:-}" == "i386_pentium4" ]]; then
        PACKAGES+=" kmod-iwlwifi iw-full pciutils"
    fi

    if [[ "${TYPE:-}" == "OPHUB" ]]; then
        PACKAGES+=" kmod-fs-btrfs btrfs-progs luci-app-amlogic"
        EXCLUDED+=" -procd-ujail"
    elif [[ "${TYPE:-}" == "ULO" ]]; then
        PACKAGES+=" luci-app-amlogic"
        EXCLUDED+=" -procd-ujail"
    fi
}

# Packages base
configure_release_packages() {
    if [[ "${BASE:-}" == "openwrt" ]]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211 luci-app-temp-status"
        EXCLUDED+=" -dnsmasq"
    elif [[ "${BASE:-}" == "immortalwrt" ]]; then
        PACKAGES+=" wpad-openssl iw iwinfo wireless-regdb kmod-cfg80211 kmod-mac80211"
        EXCLUDED+=" -dnsmasq -cpusage -automount -libustream-openssl -default-settings-chn -luci-i18n-base-zh-cn"
        if [[ "${ARCH_2:-}" == "x86_64" ]] || [[ "${ARCH_3:-}" == "i386_pentium4" ]]; then
            EXCLUDED+=" -kmod-usb-net-rtl8152-vendor"
        fi
    fi
}

# 11. Build firmware
build_firmware() {
    local target_profile="$1"
    local tunnel_option="${2:-}"
    local build_files="files"

    log "INFO" "Starting build for profile '$target_profile' with tunnel option '$tunnel_option'..."

    configure_profile_packages "$target_profile"
    add_tunnel_packages "$tunnel_option"
    configure_release_packages

    make image PROFILE="$target_profile" PACKAGES="$PACKAGES $EXCLUDED" FILES="$build_files"
    local build_status=$?

    if [ "$build_status" -eq 0 ]; then
        log "SUCCESS" "Build completed successfully!"
    else
        log "ERROR" "Build failed with exit code $build_status"
        exit "$build_status"
    fi
}

# Validasi argumen
if [ -z "${1:-}" ]; then
    log "ERROR" "Profile not specified. Usage: $0 <profile> [tunnel_option]"
    exit 1
fi

# Running Build
build_firmware "$1" "${2:-}"

#!/usr/bin/env bash

#
# matter-controller.sh
#
# Universal Matter chip-tool launcher
# - Wi-Fi commissioning
# - Thread commissioning
# - QR/manual/NFC payload generation
#
# Usage:
#
#   ./matter-controller.sh wifi
#   ./matter-controller.sh thread
#   ./matter-controller.sh qr
#   ./matter-controller.sh manual
#

set -e

CHIP_TOOL=${CHIP_TOOL:-./chip-tool}

NODE_ID=${NODE_ID:-1234}

SETUP_PIN=${SETUP_PIN:-20202021}
DISCRIMINATOR=${DISCRIMINATOR:-3840}

VENDOR_ID=${VENDOR_ID:-0xFFF1}
PRODUCT_ID=${PRODUCT_ID:-0x8000}

WIFI_SSID=${WIFI_SSID:-MyWiFi}
WIFI_PASSWORD=${WIFI_PASSWORD:-mypassword}

THREAD_DATASET=${THREAD_DATASET:-""}

BLE_ADAPTER=${BLE_ADAPTER:-0}

function banner() {
    echo
    echo "================================================="
    echo "$1"
    echo "================================================="
    echo
}

function check_chip_tool() {
    if ! command -v ${CHIP_TOOL} >/dev/null 2>&1; then
        echo "chip-tool not found: ${CHIP_TOOL}"
        exit 1
    fi
}

function wifi_pairing() {

    banner "Matter Wi-Fi Commissioning"

    ${CHIP_TOOL} pairing ble-wifi \
        ${NODE_ID} \
        "${WIFI_SSID}" \
        "${WIFI_PASSWORD}" \
        ${SETUP_PIN} \
        ${DISCRIMINATOR} \
        --ble-adapter ${BLE_ADAPTER}
}

function thread_pairing() {

    banner "Matter Thread Commissioning"

    if [ -z "${THREAD_DATASET}" ]; then
        echo
        echo "THREAD_DATASET is empty"
        echo
        echo "Example:"
        echo "export THREAD_DATASET=\$(ot-ctl dataset active -x)"
        echo
        exit 1
    fi

    ${CHIP_TOOL} pairing ble-thread \
        ${NODE_ID} \
        "${THREAD_DATASET}" \
        ${SETUP_PIN} \
        ${DISCRIMINATOR} \
        --ble-adapter ${BLE_ADAPTER}
}

function generate_qr() {

    banner "Generate Matter QR Payload"

    ${CHIP_TOOL} payload generate-qrcode \
        --vendor-id ${VENDOR_ID} \
        --product-id ${PRODUCT_ID} \
        --discriminator ${DISCRIMINATOR} \
        --setup-pin-code ${SETUP_PIN}
}

function generate_manual() {

    banner "Generate Matter Manual Pairing Code"

    ${CHIP_TOOL} payload generate-manualcode \
        --vendor-id ${VENDOR_ID} \
        --product-id ${PRODUCT_ID} \
        --discriminator ${DISCRIMINATOR} \
        --setup-pin-code ${SETUP_PIN}
}

function show_help() {

cat << EOF

Matter chip-tool helper

Usage:

  $0 wifi
  $0 thread
  $0 qr
  $0 manual

Environment Variables:

  CHIP_TOOL
  NODE_ID
  SETUP_PIN
  DISCRIMINATOR

Wi-Fi:

  WIFI_SSID
  WIFI_PASSWORD

Thread:

  THREAD_DATASET

QR/NFC:

  VENDOR_ID
  PRODUCT_ID

Examples:

  export WIFI_SSID=MyAP
  export WIFI_PASSWORD=12345678

  $0 wifi

Thread:

  export THREAD_DATASET=\$(ot-ctl dataset active -x)

  $0 thread

Generate QR:

  $0 qr

Generate Manual Code:

  $0 manual

EOF
}

check_chip_tool

case "$1" in

    wifi)
        wifi_pairing
        ;;

    thread)
        thread_pairing
        ;;

    qr)
        generate_qr
        ;;

    manual)
        generate_manual
        ;;

    *)
        show_help
        ;;

esac

#!/bin/bash

set -e

FILE="mtd8.bin"
EXTRACT_DIR="_mtd8.bin.extracted"
DESKTOP="$HOME/Desktop"
CONFIG_FILE="$EXTRACT_DIR/cramfs-root/zteconfig/default_parameter"

echo "[+] Checking if $FILE exists in the current directory..."

if [ ! -f "$FILE" ]; then
    echo "[-] File $FILE not found!"
    exit 1
fi

echo "[+] Extracting firmware using binwalk..."
binwalk -e "$FILE"

if [ ! -d "$EXTRACT_DIR" ]; then
    echo "[-] Extraction directory not found!"
    exit 1
fi

# =========================
# APN INPUT SECTION
# =========================

echo ""
echo "[+] APN configuration section"
echo "Insert APNs one by one."
echo "Press ENTER twice at any time to finish."
echo ""

declare -a apn_list
last_empty=false

for i in $(seq 1 8); do
    read -p "Enter APN_config$i: " input

    if [ -z "$input" ]; then
        if [ "$last_empty" = true ]; then
            echo "[+] Double ENTER detected → stopping input..."
            break
        fi
        last_empty=true
    else
        last_empty=false
    fi

    apn_list[$i]="$input"
done

echo "[+] Writing APNs into config file..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] Config file not found: $CONFIG_FILE"
    exit 1
fi

for i in $(seq 1 8); do
    value="${apn_list[$i]}"
    value="${value:-}"

    sed -i "s|^APN_config$i=.*|APN_config$i=$value|" "$CONFIG_FILE"
done

echo "[+] APN configuration updated."

echo "[DEBUG] Current APN config:"
grep APN_config "$CONFIG_FILE"

echo ""
echo "[+] Press ENTER to continue and rebuild firmware..."
read

# =========================
# REBUILD SECTION
# =========================

cd "$EXTRACT_DIR"

if [ ! -d "cramfs-root" ]; then
    echo "[-] cramfs-root directory not found!"
    exit 1
fi

echo "[+] Rebuilding cramfs filesystem..."
mkcramfs cramfs-root cramfs-root.cramfs

echo "[+] Removing original cramfs-root directory..."
rm -rf cramfs-root

if [ ! -f "0.cramfs" ]; then
    echo "[-] File 0.cramfs not found!"
    exit 1
fi

echo "[+] Merging filesystems..."
cat 0.cramfs cramfs-root.cramfs > mtd8_edit.bin

echo "[+] Creating final firmware image..."
dd if=mtd8_edit.bin of=mtd8_newfile.bin bs=1 skip=4804608 status=progress

echo "[+] Copying final file to Desktop..."
cp mtd8_newfile.bin "$DESKTOP/"

# =========================
# CLEANUP SECTION (FULL)
# =========================

echo "[+] Cleaning all temporary files..."

cd ..
rm -rf "$EXTRACT_DIR"
rm -f "$DESKTOP/mtd8_edit.bin"
rm -f "$DESKTOP/cramfs-root.cramfs"

echo ""
echo "[✔] Operation completed!"
echo "[✔] Final file ready: $DESKTOP/mtd8_newfile.bin"
echo "[✔] All temporary files removed."

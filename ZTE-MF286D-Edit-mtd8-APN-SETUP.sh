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
    echo ""
    echo "Config slot $i"

    read -r -p "APN Name: " name

    if [ -z "$name" ]; then
        if [ "$last_empty" = true ]; then
            echo "[+] Double ENTER detected → stopping input..."
            break
        fi
        last_empty=true
        continue
    fi

    last_empty=false

    read -r -p "APN: " apn

    if [ -z "$apn" ]; then
        last_empty=true
        continue
    fi

    last_empty=false

    apn_string="${name}(\$)${apn}(\$)manual(\$)*99#(\$)(\$)(\$)(\$)IP(\$)auto(\$)(\$)auto(\$)(\$)"
    apn_list[$i]="$apn_string"
done

echo "[+] Writing APNs into config file..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] Config file not found: $CONFIG_FILE"
    exit 1
fi

for i in $(seq 1 8); do
    value="${apn_list[$i]}"
    value="${value:-}"

    if grep -q "^APN_config$i=" "$CONFIG_FILE"; then
        sed -i "s|^APN_config$i=.*|APN_config$i=$value|" "$CONFIG_FILE"
    else
        echo "APN_config$i=$value" >> "$CONFIG_FILE"
    fi
done

echo "[+] APN configuration updated."

echo "[DEBUG] Current APN config:"
grep APN_config "$CONFIG_FILE"

echo ""
echo "[+] Press ENTER to continue and rebuild firmware..."
read -r

# =========================
# REBUILD SECTION
# =========================

cd "$EXTRACT_DIR" || exit 1

echo "[+] Entered extraction directory: $EXTRACT_DIR"

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

# =========================
# MERGE + BINWALK
# =========================

echo "[+] Merging filesystems (NEW ORDER)..."
cat cramfs-root.cramfs 0.cramfs > mtd8_edit.bin

echo ""
echo "[+] Analyzing merged firmware with binwalk..."
echo "---------------------------------------------"
binwalk mtd8_edit.bin
echo "---------------------------------------------"

echo ""
echo "[+] Take the DECIMAL offset of the second partition."
echo "[+] That value will be used as SKIP."
echo ""

read -r -p "Enter skip value (bytes): " SKIP_VALUE

if ! [[ "$SKIP_VALUE" =~ ^[0-9]+$ ]]; then
    echo "[-] Invalid number!"
    exit 1
fi

# =========================
# FINAL BUILD
# =========================

echo "[+] Creating final firmware image with skip=$SKIP_VALUE ..."
dd if=mtd8_edit.bin of=mtd8_newfile.bin bs=1 skip="$SKIP_VALUE" status=progress

echo ""
echo "[+] Verifying final firmware with binwalk..."
echo "---------------------------------------------"
binwalk mtd8_newfile.bin
echo "---------------------------------------------"

echo "[+] Copying final file to Desktop..."
cp mtd8_newfile.bin "$DESKTOP/"

# =========================
# CLEANUP
# =========================

echo "[+] Cleaning all temporary files..."

cd ..
rm -rf "$EXTRACT_DIR"

echo ""
echo "[✔] Operation completed!"
echo "[✔] Final file ready: $DESKTOP/mtd8_newfile.bin"

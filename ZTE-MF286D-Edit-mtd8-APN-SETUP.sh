#!/bin/bash

set -e

# =========================
# VARIABILI GLOBALI
# =========================

FILE="mtd8.bin"
WORK_DIR="$(pwd)"
EXTRACT_DIR="$WORK_DIR/_mtd8.bin.extracted"
DESKTOP="$HOME/Desktop"
CONFIG_FILE="$EXTRACT_DIR/cramfs-root/zteconfig/default_parameter"

# =========================
# CHECK FILE
# =========================

echo "[+] Checking if $FILE exists in the current directory..."

if [ ! -f "$FILE" ]; then
    echo "[-] File $FILE not found in $(pwd)"
    exit 1
fi

# =========================
# ESTRAZIONE
# =========================

echo "[+] Extracting firmware using binwalk..."
binwalk -e "$FILE"

if [ ! -d "$EXTRACT_DIR" ]; then
    echo "[-] Extraction directory not found: $EXTRACT_DIR"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] Config file not found: $CONFIG_FILE"
    exit 1
fi

# =========================
# APN INPUT
# =========================

echo ""
echo "[+] APN configuration section"
echo "    Insert APNs one by one (max 8)."
echo "    Leave 'APN Name' empty and press ENTER to finish."
echo ""

declare -a apn_list

for i in $(seq 1 8); do
    echo "--- Config slot $i ---"

    read -r -p "  APN Name (ENTER to stop): " name

    if [ -z "$name" ]; then
        echo "[+] No name entered → stopping APN input."
        break
    fi

    read -r -p "  APN address: " apn

    if [ -z "$apn" ]; then
        echo "[!] APN address empty, skipping slot $i."
        continue
    fi

    apn_list[$i]="${name}(\$)${apn}(\$)manual(\$)*99#(\$)(\$)(\$)(\$)IP(\$)auto(\$)(\$)auto(\$)(\$)"

    echo "  [✔] Slot $i saved: ${apn_list[$i]}"
    echo ""
done

# =========================
# SCRITTURA CONFIG
# =========================

echo "[+] Writing APNs into config file..."

for i in $(seq 1 8); do
    value="${apn_list[$i]:-}"

    if grep -q "^APN_config${i}=" "$CONFIG_FILE"; then
        sed -i "s|^APN_config${i}=.*|APN_config${i}=${value}|" "$CONFIG_FILE"
    else
        echo "APN_config${i}=${value}" >> "$CONFIG_FILE"
    fi
done

echo "[+] APN configuration updated."
echo ""
echo "[DEBUG] Current APN config in file:"
echo "---------------------------------------------"
grep "^APN_config" "$CONFIG_FILE" || echo "(no APN_config lines found)"
echo "---------------------------------------------"

echo ""
read -r -p "[+] Press ENTER to continue and rebuild firmware..."

# =========================
# REBUILD CRAMFS
# =========================

cd "$EXTRACT_DIR" || { echo "[-] Cannot cd into $EXTRACT_DIR"; exit 1; }

echo "[+] Entered: $EXTRACT_DIR"

if [ ! -d "cramfs-root" ]; then
    echo "[-] cramfs-root directory not found!"
    exit 1
fi

echo "[+] Rebuilding cramfs filesystem..."

if command -v mkcramfs &>/dev/null; then
    mkcramfs cramfs-root cramfs-root.cramfs
elif command -v mkfs.cramfs &>/dev/null; then
    mkfs.cramfs cramfs-root cramfs-root.cramfs
else
    echo "[-] Neither mkcramfs nor mkfs.cramfs found!"
    echo "    Install with: sudo apt install cramfsprogs"
    exit 1
fi

echo "[+] Removing cramfs-root directory..."
rm -rf cramfs-root

if [ ! -f "0.cramfs" ]; then
    echo "[-] File 0.cramfs not found!"
    exit 1
fi

# =========================
# MERGE
# =========================

echo "[+] Merging: 0.cramfs + cramfs-root.cramfs → mtd8_edit.bin"
cat 0.cramfs cramfs-root.cramfs > mtd8_edit.bin

echo ""
echo "[+] Analyzing merged firmware with binwalk..."
echo "---------------------------------------------"
binwalk mtd8_edit.bin
echo "---------------------------------------------"

# =========================
# LEGGI AUTOMATICAMENTE L'OFFSET DELLA SECONDA PARTIZIONE
# =========================

echo ""
echo "[+] Auto-detecting offset of second CramFS partition..."

# Prende il secondo offset CramFS dall'output di binwalk
SKIP_VALUE=$(binwalk mtd8_edit.bin | grep -i "cramfs" | awk 'NR==2{print $1}')

if [ -z "$SKIP_VALUE" ]; then
    echo "[-] Could not auto-detect second partition offset!"
    echo "    Check binwalk output above."
    echo ""
    read -r -p "Enter skip value manually (decimal bytes): " SKIP_VALUE
fi

if ! [[ "$SKIP_VALUE" =~ ^[0-9]+$ ]]; then
    echo "[-] Invalid value: '$SKIP_VALUE'"
    exit 1
fi

echo "[+] Second partition offset detected: $SKIP_VALUE bytes (0x$(printf '%X' $SKIP_VALUE))"

# =========================
# ESTRAI SECONDA PARTIZIONE = FILE FINALE
# =========================

echo ""
echo "[+] Extracting second partition from offset $SKIP_VALUE..."

# tail -c è molto più veloce di dd bs=1
tail -c "+$((SKIP_VALUE + 1))" mtd8_edit.bin > mtd8_newfile.bin

echo ""
echo "[+] Verifying final firmware with binwalk..."
echo "---------------------------------------------"
binwalk mtd8_newfile.bin
echo "---------------------------------------------"

# Il risultato deve mostrare UNA SOLA partizione CramFS a offset 0
CRAMFS_COUNT=$(binwalk mtd8_newfile.bin | grep -ic "cramfs")

if [ "$CRAMFS_COUNT" -eq 1 ]; then
    echo "[✔] OK: single CramFS partition found at offset 0."
else
    echo "[!] Warning: expected 1 CramFS partition, found $CRAMFS_COUNT"
    echo "    Check the binwalk output above."
fi

echo ""
echo "[+] Copying to Desktop..."
cp mtd8_newfile.bin "$DESKTOP/"

# =========================
# CLEANUP
# =========================

echo "[+] Cleaning up temporary files..."
cd "$WORK_DIR" || exit 1
rm -rf "$EXTRACT_DIR"

echo ""
echo "[✔] Done!"
echo "[✔] Final file: $DESKTOP/mtd8_newfile.bin"

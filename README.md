# ZTE MTD8 Firmware Editor – Automatic APN Setup

This script automates the full workflow of:

firmware extraction
APN configuration editing
filesystem rebuilding
firmware reconstruction

It is designed for ZTE firmware analysis, customization, and testing, specifically targeting the MTD8 partition.

How the Script Works
1. Firmware Validation

The script first checks if the required file exists:

<pre>mtd8.bin</pre>

If the file is missing, execution stops immediately.
This prevents invalid operations or accidental misuse.

# Firmware Extraction

The firmware is extracted using binwalk:

detects embedded filesystems
extracts the CRAMFS filesystem
creates the working directory:

<pre>_mtd8.bin.extracted/</pre>

This directory contains the router’s internal Linux filesystem.

# Interactive APN Editor

The script includes an interactive interface to configure APNs.

It supports up to 8 APN slots:
<pre>
APN_config1=
APN_config2=
...
APN_config8=</pre>

Input behavior
Enter APNs one by one
Press ENTER twice to stop input
Empty values are allowed and preserved

# Example
<pre>
APN Name: TIM
APN: internet.it

APN Name: HO
APN: web.ho-mobile.it

APN Name: ILIAD
APN: iliad

(Press ENTER twice to exit)
</pre>

# Configuration Injection

The script modifies:

<pre>zteconfig/default_parameter</pre>

It:

updates each APN_configX= entry
uses sed for safe replacement
preserves empty fields without corruption

This directly updates the router’s default APN configuration

# Filesystem Rebuild

After modification:

the filesystem is rebuilt using:

<pre>mkcramfs</pre>

the original extracted directory is removed

Result: a clean, valid filesystem ready to be embedded back into the firmware.

# Firmware Reconstruction (Advanced Step)

The firmware is rebuilt by combining:

original filesystem → 0.cramfs
modified filesystem → cramfs-root.cramfs
New merge order

<pre>cat cramfs-root.cramfs 0.cramfs > mtd8_edit.bin</pre>

# Partition Analysis with binwalk

Before finalizing, the script runs:

<pre>binwalk mtd8_edit.bin
</pre>

# Exaple output

<pre>DECIMAL       HEXADECIMAL     DESCRIPTION
---------------------------------------------------------
0             0x0             CramFS filesystem ...
4804608       0x494000        CramFS filesystem ...</pre>

# Manual SKIP Input

You must:

👉 Copy the DECIMAL offset of the second partition

Then enter it when prompted:

<pre>Enter skip value (bytes):</pre>

Why SKIP is Important

The skip value is used to realign the firmware:

<pre>dd if=mtd8_edit.bin of=mtd8_newfile.bin bs=1 skip=OFFSET</pre>

# Final Verification

The script automatically runs:

<pre>binwalk mtd8_newfile.bin</pre>

# Expected result:

0    0x0    CramFS filesystem ...

👉 This confirms the partition is correctly aligned.

# Final Output

The final firmware is saved to:

<pre>~/Desktop/mtd8_newfile.bin</pre>

# Automatic Cleanup

The script removes:

extracted firmware directory
temporary files
intermediate build artifacts

# Quick Tutorial (Step-by-Step)
Place mtd8.bin in the script directory
Run:

<pre>chmod +x ZTE-MF286D-Edit-mtd8-APN-SETUP.sh
./ZTE-MF286D-Edit-mtd8-APN-SETUP.sh</pre>

Enter APN values
Press ENTER twice to finish
Wait for binwalk output
Copy the second partition offset
Enter it when prompted
Verify the final result

# ⚠️ Important Notes
This tool modifies low-level firmware structures
Incorrect usage can brick your device

Use only on:

devices you own
test environments
research purposes

# Flashing via Serial (MTD8)

Example commands:

<pre>
setenv ipaddr 192.168.32.1
setenv serverip 192.168.32.2
saveenv
tftp mtd8.bin
nand erase 0x1000000 0x800000
nand write 0x84000000 0x1000000 0x800000</pre>

# First Boot Notes

During the first boot:

type reset in the serial console
press the physical RESET button

This ensures the modified firmware is properly applied.

# 📌 Summary
Extract firmware
Edit APN configuration
Inject changes into filesystem
Rebuild filesystem
Rebuild firmware
Manually control partition alignment
Clean all temporary files

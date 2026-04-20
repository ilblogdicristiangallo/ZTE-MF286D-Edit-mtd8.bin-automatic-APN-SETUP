This script automates the extraction, modification, and rebuilding of a ZTE router firmware image (MTD8 partition), with a specific focus on editing APN configuration parameters inside the extracted filesystem.

It is intended for firmware analysis, customization, and testing purposes.

# How the Script Works

1. Firmware Validation

The script starts by checking if the firmware file exists:

Input file: mtd8.bin
If the file is missing, the script exits immediately.

This prevents any operation on invalid or missing input.

2. Firmware Extraction

The firmware is unpacked using binwalk:

Automatically detects embedded filesystems
Extracts a CRAMFS filesystem
Creates the working directory:

<pre>_mtd8.bin.extracted/</pre>

This directory contains the router’s Linux-based filesystem.

# Interactive APN Configuration Editor

The script provides an interactive interface to configure APNs:

Supports up to 8 APN slots
Firmware keys:

<pre>
APN_config1=
APN_config2=
...
APN_config8=</pre>

Input behavior:

Enter APNs one by one
Press ENTER twice to exit input mode
Empty values are allowed and will remain blank

# Example:

<pre>
APN_config1: internet.it
APN_config2: web.ho-mobile.it
APN_config3: iliad
APN_config4:</pre>

# Configuration Injection

After input is completed, the script modifies:

<pre>zteconfig/default_parameter</pre>

Updates each APN_configX= entry using sed
Preserves empty values (no deletion or corruption)

This step updates the router’s default APN configuration.

# Filesystem Rebuild

Once modifications are complete:

The CRAMFS filesystem is rebuilt using:

<pre>mkcramfs</pre>

The original extracted directory is removed to avoid conflicts

This produces a valid embedded filesystem compatible with ZTE firmware.

# Firmware Reconstruction

The firmware image is rebuilt by combining:

Original 0.cramfs
Modified cramfs-root.cramfs

Output:

<pre>mtd8_edit.bin</pre>

This is the final modified firmware, ready for flashing or testing.

The file is automatically copied to the user’s Desktop.

Automatic Cleanup

The script removes all temporary files:

Extracted firmware directory
Temporary CRAMFS files
Intermediate build files

# Final result:

<pre>~/Desktop/mtd8_newfile.bin</pre>

# ⚠️ Important Notes
This tool modifies low-level firmware structures

Incorrect usage may brick the device

Use only on:

Devices you own

Test environments

Research purposes

# Summary
Extract firmware

Edit APN settings

Inject configuration into filesystem

Rebuild filesystem

Rebuild firmware image

Clean temporary files

Output final modified firmware

# Screenshots

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot1.png?raw=true">
        <img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot1.png?raw=true" width="350">
      </a><br>
      <sub>Screenshot 1</sub>
    </td>
    <td align="center">
      <a href="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot2.png?raw=true">
        <img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot2.png?raw=true" width="350">
      </a><br>
      <sub>Screenshot 2</sub>
    </td>
  </tr>

  <tr>
    <td align="center">
      <a href="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot3.png?raw=true">
        <img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot3.png?raw=true" width="350">
      </a><br>
      <sub>Screenshot 3</sub>
    </td>
    <td align="center">
      <a href="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot4.png?raw=true">
        <img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot4.png?raw=true" width="350">
      </a><br>
      <sub>Screenshot 4</sub>
    </td>
  </tr>

  <tr>
    <td align="center">
      <a href="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot5.png?raw=true">
        <img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screenshot5.png?raw=true" width="350">
      </a><br>
      <sub>Screenshot 5</sub>
    </td>
</table>

# Flashing via Serial (MTD8 Partition)

Connect via serial (PuTTY, 115200 baud)
Press ESC to interrupt boot
Use TFTP (e.g. Tftpd64)

Commands:

<pre>
setenv ipaddr 192.168.32.1
setenv serverip 192.168.32.2
saveenv
tftp mtd8.bin
nand erase 0x1000000 0x800000
nand write 0x84000000 0x1000000 0x800000</pre>

# Notes

During the first boot:

Type reset in the serial console
Press the hardware RESET button on the device

This ensures the modified firmware is correctly applied.

# 🌐 More Info

# Visit:
👉 www.ilblogdicristiangallo.com

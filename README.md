# ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP
This script automates the extraction, modification, and rebuilding of ZTE router firmware (MTD8 partition), with a focus on editing APN configuration parameters inside the extracted filesystem.

How the Script Works (ZTE Firmware APN Editor & Rebuilder)

This script automates the process of extracting, modifying, and rebuilding a ZTE router firmware image, specifically targeting the MTD8 partition, where configuration data (including APN profiles) is stored.

It is designed for firmware analysis, customization, and testing purposes.

# Firmware Validation

The script starts by checking if the firmware file exists:

Input file: mtd8.bin
If the file is missing, the script stops immediately.

This ensures that no operations are performed on invalid input.

# Firmware Extraction

The firmware is unpacked using binwalk:

Detects embedded filesystems automatically
Extracts a CRAMFS filesystem
Produces a working directory:
_mtd8.bin.extracted/

Inside this directory is the Linux-based filesystem used by the router.

# Interactive APN Configuration Editor

The script then enters an interactive mode where the user can define APN profiles:

Supports up to 8 APN slots

Format inside firmware:

APN_config1=
APN_config2=
...
APN_config8=
Input behavior:
User types APN values one by one
Press ENTER twice consecutively → exits input mode immediately
Empty values are allowed (they remain blank in the firmware)

# Example:

APN_config1: internet.it
APN_config2: web.ho-mobile.it
APN_config3: iliad
APN_config4:
Configuration Injection

After input is completed:

The script edits the file:

zteconfig/default_parameter
It updates each APN_configX= line using safe pattern replacement (sed)
Empty entries remain empty (no corruption or deletion)

This step modifies the router’s default APN configuration.

# Filesystem Rebuild

Once modifications are done:

The CRAMFS filesystem is rebuilt using:

mkcramfs
Original extracted filesystem is removed to avoid conflicts

This recreates a valid embedded Linux filesystem compatible with ZTE firmware.

# Firmware Reconstruction

The script then rebuilds the firmware image:

Combines:
Original 0.cramfs
Modified cramfs-root.cramfs
Produces:
mtd8_edit.bin

This is the updated firmware image containing the new APN configuration.

# Final Output Generation

The script extracts the final firmware segment using dd:

Produces:
mtd8_newfile.bin
This is the final modified firmware ready for flashing/testing

It is then copied to the user’s Desktop for easy access.

# Automatic Cleanup

To keep the system clean, the script removes:

Extracted firmware directory
Temporary CRAMFS files
Intermediate build files

Only the final firmware remains:

Desktop/mtd8_newfile.bin

# ⚠️ Important Notes

This tool modifies low-level firmware structures
Incorrect modifications may brick the device
It should only be used on:
Owned devices
Test environments
Research purposes

# Summary (Simple View)
Extract firmware
Let user edit APN settings
Inject APNs into config file
Rebuild filesystem
Rebuild firmware image
Clean everything
Output final modified firmware

# Screen USE
<table>
  <tr>
    <td><img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screen-APN-mtd8.bin.png?raw=true" width="200"></td>
    <td><img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screen-APN-mtd8.bin2.png?raw=true" width="200"></td>
    <td><img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screen-APN-mtd8.bin3.png?raw=true" width="200"></td>
  </tr>

  <tr>
    <td><img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screen-APN-mtd8.bin4.png?raw=true" width="200"></td>
    <td><img src="https://github.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/blob/main/ScreenShot-utility/Screen-APN-mtd8.bin5.png?raw=true" width="200"></td>
    <td></td>
  </tr>
</table>

# Install partition mtd8.bin SERIAL PORT: 
Press ESC in the serial console using PuTTY at a baud rate of 115200 over the serial connection to interrupt the boot process.

Then use Tftpd64 to transfer mtd8.bin via TFTP after stopping the bootloader.

Once the boot process is interrupted, execute the following commands:

<pre>setenv ipaddr 192.168.32.1
setenv serverip 192.168.32.2
saveenv
tftp mtd8.bin
nand erase 0x1000000 0x800000
nand write 0x84000000 0x1000000 0x800000</pre>

# NOTES 
After typing reset in the PuTTY serial terminal during the first boot sequence, press the hardware RESET button on the ZTE MF286D device.

This step is required to ensure that the modified partitions are properly applied and loaded by the system during startup.

<h1 align="center">🔧 ZTE MTD8 Firmware Editor – Automatic APN Setup</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-blue" alt="Linux">
  <img src="https://img.shields.io/badge/Tool-binwalk-orange" alt="binwalk">
  <img src="https://img.shields.io/badge/Filesystem-CramFS-green" alt="CramFS">
  <img src="https://img.shields.io/badge/Target-ZTE%20MF286D-red" alt="ZTE MF286D">
</p>

<p align="center">
This script automates the full workflow of modifying a ZTE router firmware image,
specifically the <strong>MTD8 partition</strong>.<br>
It extracts the firmware, edits the default APN configuration, rebuilds the filesystem,
reconstructs the firmware image, automatically detects the correct partition offset,
and generates a final flashable output file.
</p>

<hr>

<!-- ========================= -->
<!-- SCREENSHOTS SECTION       -->
<!-- ========================= -->

<h2>📸 Screenshots</h2>

<h3>Step 1 – Firmware Extraction and APN Input</h3>
<p align="center">
  <img
    src="https://raw.githubusercontent.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/refs/heads/main/ScreenShot-Utility/Screenshot1.png"
    alt="Screenshot 1 – Firmware extraction and APN input"
    width="900"
    style="border: 2px solid #444; border-radius: 8px; margin: 10px 0;"
  >
</p>

<h3>Step 2 – APN Configuration Written to File</h3>
<p align="center">
  <img
    src="https://raw.githubusercontent.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/refs/heads/main/ScreenShot-Utility/Screenshot2.png"
    alt="Screenshot 2 – APN configuration written"
    width="900"
    style="border: 2px solid #444; border-radius: 8px; margin: 10px 0;"
  >
</p>

<h3>Step 3 – Filesystem Rebuild and Partition Merge</h3>
<p align="center">
  <img
    src="https://raw.githubusercontent.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/refs/heads/main/ScreenShot-Utility/Screenshot3.png"
    alt="Screenshot 3 – Filesystem rebuild and merge"
    width="900"
    style="border: 2px solid #444; border-radius: 8px; margin: 10px 0;"
  >
</p>

<h3>Step 4 – Final Verification and Output</h3>
<p align="center">
  <img
    src="https://raw.githubusercontent.com/ilblogdicristiangallo/ZTE-MF286D-Edit-mtd8.bin-automatic-APN-SETUP/refs/heads/main/ScreenShot-Utility/Screenshot4.png"
    alt="Screenshot 4 – Final verification and output"
    width="900"
    style="border: 2px solid #444; border-radius: 8px; margin: 10px 0;"
  >
</p>

<hr>

<!-- ========================= -->
<!-- WHAT THE SCRIPT DOES      -->
<!-- ========================= -->

<h2>📋 What the Script Does</h2>

<ol>
  <li>Checks that <code>mtd8.bin</code> exists in the current directory</li>
  <li>Extracts the firmware using <code>binwalk</code></li>
  <li>Lets you interactively edit up to 8 APN profiles</li>
  <li>Injects the new APN values into <code>zteconfig/default_parameter</code></li>
  <li>Rebuilds the edited CramFS filesystem</li>
  <li>Merges the original first partition with the rebuilt second partition</li>
  <li>Automatically detects the offset of the second CramFS partition</li>
  <li>Extracts the second partition as the final aligned firmware file</li>
  <li>Verifies the result with <code>binwalk</code></li>
  <li>Copies the final file to the Desktop and removes temporary files</li>
</ol>

<hr>

<!-- ========================= -->
<!-- HOW THE SCRIPT WORKS      -->
<!-- ========================= -->

<h2>⚙️ How the Script Works</h2>

<!-- STEP 1 -->
<h3>1. Firmware Validation</h3>
<p>
The script first checks if the required firmware image exists:
</p>

<pre><code>mtd8.bin</code></pre>

<p>
If the file is missing, the script stops immediately.
This prevents invalid operations and accidental misuse.
</p>

<!-- STEP 2 -->
<h3>2. Firmware Extraction</h3>
<p>
The firmware is extracted using:
</p>

<pre><code>binwalk -e mtd8.bin</code></pre>

<p>
This creates the working directory:
</p>

<pre><code>_mtd8.bin.extracted/</code></pre>

<p>
Inside that directory, binwalk produces two key elements:
</p>

<pre><code>_mtd8.bin.extracted/
├── 0.cramfs          ← original first partition (untouched)
└── cramfs-root/      ← extracted editable filesystem (partition 2)</code></pre>

<table>
  <thead>
    <tr>
      <th>Item</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0.cramfs</code></td>
      <td>Original first partition, kept unchanged throughout the process</td>
    </tr>
    <tr>
      <td><code>cramfs-root/</code></td>
      <td>Extracted Linux filesystem from the second partition — this is where APNs are edited</td>
    </tr>
  </tbody>
</table>

<!-- STEP 3 -->
<h3>3. Interactive APN Editor</h3>
<p>
The script provides an interactive editor for up to <strong>8 APN slots</strong>:
</p>

<pre><code>APN_config1=
APN_config2=
...
APN_config8=</code></pre>

<p><strong>Input behavior:</strong></p>
<ul>
  <li>Enter APNs one by one</li>
  <li>Leave <strong>APN Name</strong> empty and press <code>ENTER</code> to stop input</li>
  <li>Unused slots are written as empty values</li>
</ul>

<p><strong>Example:</strong></p>

<pre><code>--- Config slot 1 ---
  APN Name (ENTER to stop): TIM
  APN address: internet.it
  [✔] Slot 1 saved

--- Config slot 2 ---
  APN Name (ENTER to stop): HO
  APN address: web.ho-mobile.it
  [✔] Slot 2 saved

--- Config slot 3 ---
  APN Name (ENTER to stop): ILIAD
  APN address: iliad
  [✔] Slot 3 saved

--- Config slot 4 ---
  APN Name (ENTER to stop): [ENTER]
  [+] No name entered → stopping APN input.</code></pre>

<!-- STEP 4 -->
<h3>4. Configuration Injection</h3>
<p>
The script modifies the following file inside the extracted filesystem:
</p>

<pre><code>cramfs-root/zteconfig/default_parameter</code></pre>

<p>
Each APN is written in ZTE's internal format:
</p>

<pre><code>APN_config1=TIM($)internet.it($)manual($)*99#($)($)($)($)IP($)auto($)($)auto($)($)</code></pre>

<p>
The script uses <code>sed</code> for safe in-place replacement of existing entries.
If a line does not exist yet, it is appended automatically.
Empty slots are preserved as blank values.
</p>

<!-- STEP 5 -->
<h3>5. Filesystem Rebuild</h3>
<p>
After editing, the modified <code>cramfs-root/</code> directory is rebuilt into a new CramFS image:
</p>

<pre><code>mkcramfs cramfs-root cramfs-root.cramfs</code></pre>

<p>
Then the extracted directory is removed:
</p>

<pre><code>rm -rf cramfs-root</code></pre>

<p>
Result: a clean rebuilt CramFS image ready to be merged into the final firmware.
</p>

<blockquote>
  <strong>Note:</strong> The script automatically detects if <code>mkcramfs</code> or
  <code>mkfs.cramfs</code> is available on your system.
</blockquote>

<!-- STEP 6 -->
<h3>6. Firmware Reconstruction</h3>
<p>
The firmware is rebuilt by concatenating the two partitions in the <strong>correct order</strong>:
</p>

<pre><code>cat 0.cramfs cramfs-root.cramfs &gt; mtd8_edit.bin</code></pre>

<table>
  <thead>
    <tr>
      <th>Position</th>
      <th>File</th>
      <th>Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>First</td>
      <td><code>0.cramfs</code></td>
      <td>Original first partition, unchanged</td>
    </tr>
    <tr>
      <td>Second</td>
      <td><code>cramfs-root.cramfs</code></td>
      <td>Rebuilt partition containing the modified APNs</td>
    </tr>
  </tbody>
</table>

<p>
The original partition must come first so that offsets match the device's bootloader expectations.
The second partition is the one containing your modifications.
</p>

<!-- STEP 7 -->
<h3>7. Partition Analysis</h3>
<p>
The script automatically analyzes the merged file:
</p>

<pre><code>binwalk mtd8_edit.bin</code></pre>

<p><strong>Example output:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian, size: 4800512 ...
4800512       0x494000        CramFS filesystem, little endian, size: 4796416 ...</code></pre>

<p>
The second CramFS entry is the rebuilt partition with your modified APNs.
</p>

<!-- STEP 8 -->
<h3>8. Automatic Offset Detection</h3>
<p>
Instead of asking the user to manually copy the offset,
the script reads it automatically:
</p>

<pre><code>binwalk mtd8_edit.bin | grep -i "cramfs" | awk 'NR==2{print $1}'</code></pre>

<p>
That offset is used to extract <strong>only the second partition</strong>
from the merged file, producing the final firmware:
</p>

<pre><code>tail -c "+$((SKIP_VALUE + 1))" mtd8_edit.bin &gt; mtd8_newfile.bin</code></pre>

<blockquote>
  <strong>Why <code>tail -c</code>?</strong>
  It is significantly faster than <code>dd bs=1</code> when working with large binary files.
</blockquote>

<!-- STEP 9 -->
<h3>9. Final Verification</h3>
<p>
The script verifies the generated file:
</p>

<pre><code>binwalk mtd8_newfile.bin</code></pre>

<p><strong>Expected result:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian ...</code></pre>

<p>
✅ A <strong>single CramFS partition at offset 0</strong> confirms the firmware is correctly aligned
and ready to flash.
</p>

<!-- STEP 10 -->
<h3>10. Final Output</h3>
<p>
The final file is automatically copied to:
</p>

<pre><code>~/Desktop/mtd8_newfile.bin</code></pre>

<!-- STEP 11 -->
<h3>11. Automatic Cleanup</h3>
<p>
The script removes all temporary files and directories:
</p>

<pre><code>rm -rf _mtd8.bin.extracted/</code></pre>

<p>This includes:</p>
<ul>
  <li>The extracted filesystem directory</li>
  <li>Intermediate <code>.cramfs</code> build files</li>
  <li>The merged <code>mtd8_edit.bin</code> file</li>
</ul>

<hr>

<!-- ========================= -->
<!-- REQUIREMENTS              -->
<!-- ========================= -->

<h2>🛠️ Requirements</h2>

<p>Make sure the following tools are installed:</p>

<table>
  <thead>
    <tr>
      <th>Tool</th>
      <th>Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>binwalk</code></td>
      <td>Firmware extraction and analysis</td>
    </tr>
    <tr>
      <td><code>mkcramfs</code> or <code>mkfs.cramfs</code></td>
      <td>CramFS filesystem rebuild</td>
    </tr>
    <tr>
      <td><code>sed</code></td>
      <td>In-place text editing</td>
    </tr>
    <tr>
      <td><code>awk</code></td>
      <td>Offset parsing from binwalk output</td>
    </tr>
    <tr>
      <td><code>grep</code></td>
      <td>Pattern matching</td>
    </tr>
    <tr>
      <td><code>tail</code></td>
      <td>Binary extraction by byte offset</td>
    </tr>
  </tbody>
</table>

<p>On Debian / Kali / Ubuntu:</p>

<pre><code>sudo apt update
sudo apt install binwalk cramfsprogs</code></pre>

<hr>

<!-- ========================= -->
<!-- QUICK TUTORIAL            -->
<!-- ========================= -->

<h2>🚀 Quick Tutorial</h2>

<ol>
  <li>Place <code>mtd8.bin</code> in the same directory as the script</li>
  <li>Make the script executable and run it:</li>
</ol>

<pre><code>chmod +x ZTE-MF286D-Edit-mtd8-APN-SETUP.sh
./ZTE-MF286D-Edit-mtd8-APN-SETUP.sh</code></pre>

<ol start="3">
  <li>Enter your APN values when prompted</li>
  <li>Leave <strong>APN Name</strong> empty and press <code>ENTER</code> to finish APN input</li>
  <li>Wait for the script to rebuild and verify automatically</li>
  <li>Retrieve the final file from your Desktop:</li>
</ol>

<pre><code>~/Desktop/mtd8_newfile.bin</code></pre>

<hr>

<!-- ========================= -->
<!-- EXAMPLE WORKFLOW          -->
<!-- ========================= -->

<h2>📝 Example Workflow</h2>

<pre><code># After extraction and APN editing:
mkcramfs cramfs-root cramfs-root.cramfs
rm -rf cramfs-root
cat 0.cramfs cramfs-root.cramfs &gt; mtd8_edit.bin
binwalk mtd8_edit.bin</code></pre>

<p><strong>Example binwalk output:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian, size: 4800512 ...
4800512       0x494000        CramFS filesystem, little endian, size: 4796416 ...</code></pre>

<p>
The script extracts only the second partition and produces a final file
with a single CramFS filesystem starting at offset <code>0x0</code>,
with no extra embedded segments or unwanted zlib entries.
</p>

<hr>

<!-- ========================= -->
<!-- WARNING                   -->
<!-- ========================= -->

<h2>⚠️ Important Notes</h2>

<blockquote>
  <p>
    <strong>WARNING:</strong> This tool modifies <strong>low-level firmware structures</strong>.<br>
    Incorrect usage may <strong>permanently damage or brick</strong> your device.
  </p>
</blockquote>

<p>Use it only on:</p>
<ul>
  <li>✅ Devices you own</li>
  <li>✅ Test environments</li>
  <li>✅ Research or educational purposes</li>
</ul>

<hr>

<!-- ========================= -->
<!-- FLASHING                  -->
<!-- ========================= -->

<h2>🔌 Flashing via Serial Console</h2>

<p>
Example U-Boot commands for flashing the MTD8 firmware via TFTP:
</p>

<pre><code>setenv ipaddr 192.168.32.1
setenv serverip 192.168.32.2
saveenv
tftp mtd8.bin
nand erase 0x1000000 0x800000
nand write 0x84000000 0x1000000 0x800000
reset
</code></pre>

<h3>First Boot Notes</h3>
<p>
After flashing, during the first boot:
</p>

<ul>
  <li>Type <code>reset</code> in the serial console, <strong>or</strong></li>
  <li>Press the physical <strong>RESET</strong> button on the device</li>
</ul>

<p>
This ensures the modified firmware is properly initialized and the new APN configuration is loaded.
</p>

<hr>

<!-- ========================= -->
<!-- SUMMARY TABLE             -->
<!-- ========================= -->

<h2>📌 Summary</h2>

<table>
  <thead>
    <tr>
      <th>Step</th>
      <th>Action</th>
      <th>Tool</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Validate <code>mtd8.bin</code></td>
      <td><code>bash</code></td>
    </tr>
    <tr>
      <td>2</td>
      <td>Extract firmware</td>
      <td><code>binwalk -e</code></td>
    </tr>
    <tr>
      <td>3</td>
      <td>Edit APN values interactively</td>
      <td><code>read</code></td>
    </tr>
    <tr>
      <td>4</td>
      <td>Inject changes into config file</td>
      <td><code>sed</code></td>
    </tr>
    <tr>
      <td>5</td>
      <td>Rebuild CramFS filesystem</td>
      <td><code>mkcramfs</code></td>
    </tr>
    <tr>
      <td>6</td>
      <td>Merge partitions in correct order</td>
      <td><code>cat</code></td>
    </tr>
    <tr>
      <td>7</td>
      <td>Analyze merged firmware</td>
      <td><code>binwalk</code></td>
    </tr>
    <tr>
      <td>8</td>
      <td>Auto-detect second partition offset</td>
      <td><code>awk</code></td>
    </tr>
    <tr>
      <td>9</td>
      <td>Extract final aligned firmware</td>
      <td><code>tail -c</code></td>
    </tr>
    <tr>
      <td>10</td>
      <td>Verify final output</td>
      <td><code>binwalk</code></td>
    </tr>
    <tr>
      <td>11</td>
      <td>Copy to Desktop and cleanup</td>
      <td><code>cp</code> / <code>rm</code></td>
    </tr>
  </tbody>
</table>

<hr>

<p align="center">
  <strong>Made for ZTE MF286D firmware research and customization.</strong><br>
  Use responsibly. 🔒
</p> 

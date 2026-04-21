<h1>ZTE MTD8 Firmware Editor – Automatic APN Setup</h1>

<p>
This script automates the full workflow of modifying a ZTE router firmware image,
specifically the <strong>MTD8 partition</strong>.
It extracts the firmware, edits the default APN configuration, rebuilds the filesystem,
reconstructs the firmware image, automatically detects the correct partition offset,
and generates a final flashable output file.
</p>

<hr>

<h2>What the Script Does</h2>

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

<h2>How the Script Works</h2>

<h3>1. Firmware Validation</h3>
<p>
The script first checks if the required firmware image exists:
</p>

<pre><code>mtd8.bin</code></pre>

<p>
If the file is missing, the script stops immediately.
This prevents invalid operations and accidental misuse.
</p>

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
Inside that directory, the script works with two key elements:
</p>

<pre><code>_mtd8.bin.extracted/
├── 0.cramfs
└── cramfs-root/</code></pre>

<ul>
  <li><code>0.cramfs</code> = original first partition, kept unchanged</li>
  <li><code>cramfs-root/</code> = extracted editable filesystem used for APN modification</li>
</ul>

<h3>3. Interactive APN Editor</h3>
<p>
The script provides an interactive APN editor for up to 8 APN slots:
</p>

<pre><code>APN_config1=
APN_config2=
...
APN_config8=</code></pre>

<p><strong>Input behavior:</strong></p>
<ul>
  <li>Enter APNs one by one</li>
  <li>Leave <strong>APN Name</strong> empty and press <code>ENTER</code> to stop</li>
  <li>Unused slots are written as empty values</li>
</ul>

<p><strong>Example:</strong></p>

<pre><code>APN Name: TIM
APN: internet.it

APN Name: HO
APN: web.ho-mobile.it

APN Name: ILIAD
APN: iliad

APN Name: [ENTER to stop]</code></pre>

<h3>4. Configuration Injection</h3>
<p>
The script modifies the following file inside the extracted filesystem:
</p>

<pre><code>cramfs-root/zteconfig/default_parameter</code></pre>

<p>
Each APN is written into the router's internal format.
Example:
</p>

<pre><code>APN_config1=TIM($)internet.it($)manual($)*99#($)($)($)($)IP($)auto($)($)auto($)($)</code></pre>

<p>
The script safely updates existing <code>APN_configX=</code> entries using <code>sed</code>.
If a line does not exist, it is appended automatically.
</p>

<h3>5. Filesystem Rebuild</h3>
<p>
After editing, the modified filesystem is rebuilt into a new CramFS image:
</p>

<pre><code>mkcramfs cramfs-root cramfs-root.cramfs</code></pre>

<p>
Then the extracted directory is removed:
</p>

<pre><code>rm -rf cramfs-root</code></pre>

<p>
This produces a clean rebuilt filesystem image ready to be merged.
</p>

<h3>6. Firmware Reconstruction</h3>
<p>
The script rebuilds the firmware by concatenating the two partitions in the correct order:
</p>

<pre><code>cat 0.cramfs cramfs-root.cramfs &gt; mtd8_edit.bin</code></pre>

<p>
This is important:
</p>

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
      <td>Rebuilt second partition containing the modified APNs</td>
    </tr>
  </tbody>
</table>

<p>
The goal is to create a merged file where the <strong>second partition becomes the edited rebuilt filesystem</strong>,
while the first partition remains the original one.
</p>

<h3>7. Partition Analysis</h3>
<p>
The script analyzes the merged file using:
</p>

<pre><code>binwalk mtd8_edit.bin</code></pre>

<p><strong>Example output:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian, size: 4800512 ...
4800512       0x494000        CramFS filesystem, little endian, size: 4796416 ...</code></pre>

<p>
The second CramFS partition begins at the second decimal offset shown by <code>binwalk</code>.
</p>

<h3>8. Automatic Offset Detection</h3>
<p>
Instead of asking the user to manually copy the offset,
the script automatically reads the decimal offset of the second CramFS partition.
</p>

<pre><code>binwalk mtd8_edit.bin | grep -i "cramfs" | awk 'NR==2{print $1}'</code></pre>

<p>
That offset is then used to extract only the second partition from the merged file.
</p>

<h3>9. Final Firmware Extraction</h3>
<p>
The final output is generated from the second partition only:
</p>

<pre><code>tail -c "+$((SKIP_VALUE + 1))" mtd8_edit.bin &gt; mtd8_newfile.bin</code></pre>

<p>
This produces a final firmware file where the filesystem starts at offset <code>0x0</code>.
</p>

<h3>10. Final Verification</h3>
<p>
The script verifies the generated file using:
</p>

<pre><code>binwalk mtd8_newfile.bin</code></pre>

<p><strong>Expected result:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian ...</code></pre>

<p>
If only one CramFS filesystem is found at offset <code>0</code>,
the image is correctly aligned.
</p>

<h3>11. Final Output</h3>
<p>
The final file is copied automatically to:
</p>

<pre><code>~/Desktop/mtd8_newfile.bin</code></pre>

<h3>12. Automatic Cleanup</h3>
<p>
At the end, the script removes the extracted working directory and temporary files:
</p>

<pre><code>rm -rf _mtd8.bin.extracted/</code></pre>

<hr>

<h2>Requirements</h2>

<p>
Make sure the following tools are installed:
</p>

<ul>
  <li><code>binwalk</code></li>
  <li><code>mkcramfs</code> or <code>mkfs.cramfs</code></li>
  <li><code>sed</code></li>
  <li><code>awk</code></li>
  <li><code>grep</code></li>
  <li><code>tail</code></li>
</ul>

<p>
On Debian/Kali/Ubuntu systems you can usually install the required tools with:
</p>

<pre><code>sudo apt update
sudo apt install binwalk cramfsprogs</code></pre>

<hr>

<h2>Quick Tutorial</h2>

<ol>
  <li>Place <code>mtd8.bin</code> in the same directory as the script</li>
  <li>Make the script executable</li>
  <li>Run it</li>
  <li>Enter your APN values when prompted</li>
  <li>Leave <strong>APN Name</strong> empty and press <code>ENTER</code> when finished</li>
  <li>Wait for automatic rebuild and verification</li>
  <li>Retrieve the final file from your Desktop</li>
</ol>

<pre><code>chmod +x ZTE-MF286D-Edit-mtd8-APN-SETUP.sh
./ZTE-MF286D-Edit-mtd8-APN-SETUP.sh</code></pre>

<hr>

<h2>Example Workflow</h2>

<pre><code>mkcramfs cramfs-root cramfs-root.cramfs
rm -r cramfs-root
cat 0.cramfs cramfs-root.cramfs &gt; mtd8_edit.bin
binwalk mtd8_edit.bin</code></pre>

<p><strong>Example result:</strong></p>

<pre><code>DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             CramFS filesystem, little endian, size: 4800512 ...
4800512       0x494000        CramFS filesystem, little endian, size: 4796416 ...</code></pre>

<p>
The final file extracted from the second partition will then contain a single filesystem at offset <code>0</code>,
without extra embedded segments or unwanted zlib entries.
</p>

<hr>

<h2>Important Notes</h2>

<p>
This tool modifies <strong>low-level firmware structures</strong>.
Incorrect usage may permanently damage or brick your device.
</p>

<p>Use it only on:</p>
<ul>
  <li>Devices you own</li>
  <li>Test environments</li>
  <li>Research or educational purposes</li>
</ul>

<hr>

<h2>Flashing via Serial Console</h2>

<p>
Example U-Boot commands for flashing the MTD8 firmware via TFTP:
</p>

<pre><code>setenv ipaddr 192.168.32.1
setenv serverip 192.168.32.2
saveenv
tftp mtd8.bin
nand erase 0x1000000 0x800000
nand write 0x84000000 0x1000000 0x800000</code></pre>

<h3>First Boot Notes</h3>
<p>
After flashing, during the first boot:
</p>

<ul>
  <li>type <code>reset</code> in the serial console, or</li>
  <li>press the physical <strong>RESET</strong> button on the device</li>
</ul>

<p>
This helps the router properly initialize the modified firmware and apply the new APN configuration.
</p>

<hr>

<h2>Summary</h2>

<table>
  <thead>
    <tr>
      <th>Step</th>
      <th>Action</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>1</td>
      <td>Validate <code>mtd8.bin</code></td>
    </tr>
    <tr>
      <td>2</td>
      <td>Extract firmware with <code>binwalk</code></td>
    </tr>
    <tr>
      <td>3</td>
      <td>Edit APN values interactively</td>
    </tr>
    <tr>
      <td>4</td>
      <td>Inject changes into <code>default_parameter</code></td>
    </tr>
    <tr>
      <td>5</td>
      <td>Rebuild the edited CramFS filesystem</td>
    </tr>
    <tr>
      <td>6</td>
      <td>Merge original first partition with rebuilt second partition</td>
    </tr>
    <tr>
      <td>7</td>
      <td>Auto-detect second partition offset</td>
    </tr>
    <tr>
      <td>8</td>
      <td>Extract final aligned firmware image</td>
    </tr>
    <tr>
      <td>9</td>
      <td>Verify with <code>binwalk</code></td>
    </tr>
    <tr>
      <td>10</td>
      <td>Copy to Desktop and clean temporary files</td>
    </tr>
  </tbody>
</table>

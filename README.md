# qvm-create-windows-qube

qvm-create-windows-qube is a tool for quickly and conveniently installing fresh new Windows [qubes](https://www.qubes-os.org) with Qubes Windows Tools as well as other packages such as Firefox, Office 365, Notepad++ and Visual Studio pre-installed modularly and automatically.

## Installation

1. Download the [installation script](https://raw.githubusercontent.com/elliotkillick/qvm-create-windows-qube/master/install.sh) by opening the link, right-clicking and then selecting "Save as..."
2. Copy `install.sh` into Dom0 by running the following command in Dom0: `qvm-run -p --filter-escape-chars --no-color-output <qube_script_is_located_on> "cat '/home/user/Downloads/install.sh'" > install.sh`
3. Review the code of `install.sh` to ensure its integrity
4. Run `chmod +x install.sh && ./install.sh`
5. Review the code of the resulting `qvm-create-windows-qube.sh`

Please see QWT Known Issues below before proceeding.

## Usage

```
Usage: ./qvm-create-windows-qube.sh [options] <name>
  -h, --help
  -c, --count <number> Number of Windows qubes with given basename desired
  -t, --template Make this qube a TemplateVM instead of a StandaloneVM
  -n, --netvm <qube> NetVM for Windows to use (default: sys-firewall)
  -s, --seamless Enable seamless mode persistently across restarts
  -o, --optimize Optimize Windows by disabling unnecessary functionality for a qube
  -y, --anti-spy Non-invasively disable and block Windows telemetry
  -p, --packages <packages> Comma-separated list of packages to pre-install (see available packages at: https://chocolatey.org/packages)
  -i, --iso <file> Windows media to automatically install and setup (default: Win7_Pro_SP1_English_x64.iso)
  -a, --answer-file <xml file> Settings for Windows installation (default: windows-7.xml)
```

Example: `./qvm-create-windows-qube.sh -n sys-firewall -soyp firefox,notepadplusplus,office365business windows-7`

Note: If the Qubes GUI driver is unwanted, either due to stability or peformance issues, then that can be disabled by going into the answer file and removing everything under the RunSynchronus tag for enabling test signing. Make sure you also cause a new ISO to be generated by deleting the old unattended one in the out folder. This works because the GUI driver is the only unsigned driver and the installer will automatically not install the GUI driver if it detects test signing is disabled.

## QWT Known Issues

HVMs (Windows, sys-net, etc.):
    - Until this [bug](https://github.com/QubesOS/qubes-issues/issues/4684) is fixed upstream you must fix app menu syncing for HVMs (Windows, sys-net, etc.) by putting the provided `qubes-start.desktop` into `/usr/share/qubes-appmenus` in Dom0
All OSs:
    - Windows may crash on first boot after QWT is installed
        - On Windows 7, the desktop may boot back up to having no wallpaper and missing libraries. Just delete that qube and start over
        - Or it might just hang on trying to copy the post scripts over to the crashed qube
    - In general, sometimes Windows will crash during boot when trying to display screen with Qubes GUI driver (suspected). This can happen due to the "Welcome" loading screen that shows up or manipulating the window by resizing, mimimizing, etc. during boot
    - Add audio support: https://github.com/QubesOS/qubes-issues/issues/2624
All OSs except Windows 7:
    - Don't use -s/--seamless option or GUI won't show up
    - Run `qvm-featues <windows_qube> gui 1` to make display show up after QWT setup
    - When Qubes GUI driver is in use, may receive a message saying Windows is trying to break spoof Dom0 GUI causing installation to pause. Fix by closing window.
    - Running qrexec services (app menu (icons show up but clicking them won't open app), qvm-run --service, etc.) doesn't work: https://github.com/QubesOS/qubes-issues/issues/5091
Windows 10:
    - Private disk creation fails: https://github.com/QubesOS/qubes-issues/issues/5090. Temp fix by closing prepare-volume.exe causing there to be no private disk (can't make a template VM) but besides that it will continue as normal

See here:

https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-tools
https://github.com/QubesOS/qubes-issues/labels/C%3A%20windows-vm

Further research is required, if you're in the giving mood please jump in and fix some of these.

## Security

The resources qube, windows-mgmt by default, is air gapped. To mitigate the fallout of another [Shellshock](https://en.wikipedia.org/wiki/Shellshock_(software_bug)) Bash vulnerability, the Dom0 script communicates to the windows-mgmt qube in a one-way fashion. Downloading of the Windows ISOs are made secure by encforcing TLS 1.2/1.3 HTTPS with HTTP public key pinning (HPKP) and by verifying the SHA-256 of the files after download. Packages such as Firefox are offered out of the box so the infamously insecure Internet Explorer never has to be used.

Important: If RDP is to be enabled on the Windows qube (not default) then make sure it is fully up-to-date because the latest Windows 7 ISO Microsoft offers is unfortunately still vulnerable to [BlueKeep](https://en.wikipedia.org/wiki/BlueKeep) and related DejaBlue vulnerabilites

## Privacy

Privacy benefits by disabling unwanted Microsoft telemetry such as the Customer Experience Improvement Program (CEIP), Windows Error Reporting (WER) and Diagnostics Tracking service (DiagTrack), blocking Microsoft IPs used exclusively for telemetry, standardizing common Whonix recommeneded defaults such as "user" for the username and "host" for the hostname, and by resetting unique identifiers present in every Windows installation such as the MachineGUID, NTFS drive Volume Serial Numbers (VSNs) and more.

However, there are still ways to fingerprint you through the hypervisor (not specific to Windows): [lscpu](https://github.com/QubesOS/qubes-issues/issues/1142), [timezone](https://github.com/QubesOS/qubes-issues/issues/4429) (Can be mitigated by configuring UTC time in the BIOS/UEFI), screen resolution and depth, generally some of the VM interfaces documented [here](https://www.qubes-os.org/doc/vm-interface), as well as much more obscure things. Note that many of these pieces of information don't represent very many bits of uniquely identifiable information and just like Tor, as the [userbase of Qubes OS](https://www.qubes-os.org/statistics) grows, these datapoints become increasingly less significant.

## Contributing

You can start by giving this project a star! PRs are also welcome! Take a look at the todo list below if you're looking for things that need improvement. Other improvements such as more elegant ways of completing a task, code cleanup and other fixes are also welcome.

Note: This project is the product of an independent effort that is not offically endorsed by Qubes OS

## Todo

- [x] Gain the ability to reliably unpack/insert answer file/repack for any given ISO 9660 (Windows ISO format)
    - Blocking issue for supporting other versions of Windows
- [x] auto-qwt takes D:\\ making QWT put the user profile on E:\\; it would be nicer to have it on D:\\ so there is no awkward gap in the middle
- [ ] Support Windows 8.1-10 (Note: QWT doesn't fully support Windows 10 yet)
- [ ] Support Windows Server 2008 R2 to Windows Server 2019
- [x] Provision Chocolatey
- [x] Add an option to slim down Windows as documented in: https://www.qubes-os.org/doc/windows-template-customization/
- [x] Make windows-mgmt air gapped
- [ ] Consider installing INF drivers in OfflineServicing pass
    - While the current way of installing them certainly works (just the QWT installer executable) it would be more proper to use this pass as this is what it's for
    - Can get around Windows 7 planned obsolescence in an offical non-hacky way (See allow-device-software.vbs)
    - Can use /ForceUnsigned option in DISM to allow Qubes GUI unsigned driver
    - For this we would use [wimlib](https://wimlib.net)
    - We would definitely still have to run the QWT installation executable to setup things like the private disk
- [ ] Possibly switch from udisksctl for reading/mounting ISOs because it is written in its man page that it should not be used in scripts
    - guestfs?
    - Consider other alternatives
- [ ] Put this todo list into GitHub issues

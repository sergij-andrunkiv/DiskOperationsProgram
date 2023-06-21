# About DiskOperationsProgram
Disk management software is open source software designed to manipulate various types of storage devices.
The list of operations provided by this program:
- Displaying a list of operations on disks
- Display a list of disks connected to the computer
- Mounting drives to directories
- Unmounting the drives
- Disconnect the drives
- Create bootable devices from ISO images
- Format the drives to selected file systems
# Requirements
- Bash version 5.1.016-4 or later
- FASM version 1.73.30-1 or later
- GCC version 13.1.1 or later
- GNU Make 4.4.1 or later
# Build and Run on Debian/Arch/RHEL based Linux distrubutions
- git clone https://github.com/sergij-andrunkiv/DiskOperationsProgram
- cd DiskOperationsProgram/Sources
- make build
- make run
# License
- GNU General Public License v3.0

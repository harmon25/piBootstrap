# piBootstrap
Shell Script to Bootstrap a minimal Pi Image

Features
- Resize Root Parition
 - remove swap if it exists, recreate if enough space (8GB > SD Card)
- Reboot After modifications to partition table
 -Script Starts again after reboot to continue Bootstrapping
- Install updates and base packages
- Set and Install default Python
- Create SUDO user
- Install custom Libraries

# piBootstrap
Shell Script to Bootstrap a [minimal Pi Image](https://minibianpi.wordpress.com/)

- Should only be run once after first boot

Features
- Resize Root Parition
 - remove swap if it exists, recreate if enough space (8GB > SD Card)
- Reboot After modifications to reinitilize partition table
 -Script Starts again after reboot to continue Bootstrapping
- Install updates and base packages
- Set and Install default Python
- Install custom Libraries
 - [pigpio](http://abyz.co.uk/rpi/pigpio/)
 - [w1-temp Python Lib](https://github.com/timofurrer/w1thermsensor)
 - [Adafruit Python SSD1306](https://github.com/adafruit/Adafruit_Python_SSD1306)
- Create SUDO user
- Edit Root User PW
- Change Hostname
